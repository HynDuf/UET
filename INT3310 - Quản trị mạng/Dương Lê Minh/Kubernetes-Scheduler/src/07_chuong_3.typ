#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Trình lập lịch Kubernetes tùy chỉnh <chuong3>
]

== Kiến trúc của trình lập lịch Scheduler tùy chỉnh

Trong dự án của nhóm, chúng em đã phát triển một scheduler Kubernetes tùy chỉnh, có sẵn tại #link("https://github.com/HynDuf/custom-kubernetes-scheduler")[https://github.com/HynDuf/custom-kubernetes-scheduler], nhằm nâng cao khả năng phân bố pod tiêu chuẩn trong cụm Kubernetes. Scheduler mặc định của Kubernetes chủ yếu xét đến các _yêu cầu tài nguyên_ của pod. Scheduler tùy chỉnh của nhóm hướng tới một cách tiếp cận tinh vi hơn bằng cách tích hợp các chỉ số nút theo thời gian thực và tôn trọng các ưu tiên affinity do pod định nghĩa. Phần này trình bày kiến trúc cấp cao của hệ thống, nêu chi tiết các thành phần cốt lõi và cách chúng tương tác với nhau.

=== Sơ đồ tổng quan

// Rất khuyến khích thay thế phần mô tả văn bản này bằng một sơ đồ trực quan thực sự trong báo cáo cuối cùng.
// Một sơ đồ sẽ hỗ trợ đáng kể trong việc hiểu cấu trúc và luồng dữ liệu của hệ thống.
// Bạn có thể sử dụng các công cụ như draw.io, PlantUML hoặc TikZ (nếu bạn quen với đồ họa nâng cao LaTeX/Typst) để tạo sơ đồ.

Một sơ đồ khái niệm cho hệ thống scheduler tùy chỉnh của nhóm sẽ minh họa các thực thể và tương tác sau:

+ *Cụm Kubernetes:*
  - *Kubernetes API Server:* Thành phần trung tâm của control plane.
  - *Các Node:* Máy chủ làm việc nơi pod được thực thi.
    - *Node Exporter (DaemonSet):* Một instance Node Exporter chạy trên mỗi node, có nhiệm vụ thu thập các chỉ số mức hệ thống.
  - *Các Pod:*
    - *Pod cần được phân lịch:* Các pod này được cấu hình rõ ràng với `spec.schedulerName: custom-scheduler`.
    - *Các Pod Khác:* Các pod được quản lý bởi scheduler mặc định hoặc scheduler tùy chỉnh khác.
    
+ *Monitoring Stack (thường được triển khai trong namespace `monitoring`):*
  - *Prometheus Server:* Thành phần này tổng hợp các chỉ số từ tất cả Node Exporter và phục vụ chúng thông qua PromQL.
+ *Hệ thống Scheduler tùy chỉnh (triển khai trong namespace `kube-system`):*
  - *Pod Scheduler Tùy Chỉnh:* Pod này chạy ứng dụng Go của nhóm, hiện thân của logic phân lịch tùy chỉnh.

*Luồng tương tác chính* (được minh họa bằng mũi tên trong sơ đồ):
1. Người dùng hoặc controller tự động tạo một Pod manifest có `schedulerName: custom-scheduler` và gửi nó đến *Kubernetes API Server*.

2. *Pod Scheduler tùy chỉnh* của nhóm liên tục theo dõi *Kubernetes API Server* để tìm các pod chờ được gán scheduler.

3. Khi phát hiện một pod như vậy, scheduler sẽ truy vấn *Kubernetes API Server* để lấy trạng thái và thông số hiện tại của tất cả node để lọc sơ bộ (predicate checks).

4. Sau đó, scheduler sẽ truy vấn *Prometheus Server* để lấy các chỉ số thời gian thực (ví dụ: bộ nhớ khả dụng, phần trăm CPU không hoạt động) của các node đã vượt qua bước lọc.

5. *Prometheus Server* trả lời yêu cầu này bằng dữ liệu đã thu thập từ các instance *Node Exporter* trên mỗi node.

6. Scheduler áp dụng thuật toán tính điểm. Logic này xét đến tài nguyên khả dụng (từ Prometheus) và các tùy chọn affinity do pod định nghĩa để xếp hạng các node tương thích và chọn node phù hợp nhất.

7. Scheduler thông báo quyết định của mình cho *Kubernetes API Server* bằng cách tạo đối tượng `Binding`, gán pod vào node đã chọn.

8. Kubelet trên node được chọn nhận biết việc gán này và bắt đầu chạy pod.

=== Các thành phần chính và vai trò của chúng

Hệ thống dựa vào nhiều thành phần liên kết chặt chẽ, mỗi thành phần đóng một vai trò riêng:

==== Trình lập lịch Scheduler tùy chỉnh (Golang)

+ *Mô tả:* Đây là thành phần cốt lõi của dự án, một ứng dụng Go triển khai thuật toán lập lịch tùy chỉnh. Mã nguồn được lưu tại #link("https://github.com/HynDuf/custom-kubernetes-scheduler")[https://github.com/HynDuf/custom-kubernetes-scheduler].

+ *Vị trí:* Chạy dưới dạng _Deployment_ trong namespace `kube-system`, được định nghĩa trong tệp manifest `scheduler/custom-scheduler-deployment.yaml`.

+ *Vai trò:* Cài đặt của trình lập lịch tùy chỉnh.

+ *Trách nhiệm:*
  - Theo dõi liên tục Kubernetes API để phát hiện các pod ở trạng thái `Pending`, chưa có node (`spec.nodeName` rỗng), và có `schedulerName: custom-scheduler`.
  
  - Thực hiện kiểm tra predicate (xem xét yêu cầu tài nguyên, taint/toleration, node selector) để xác định danh sách node _có thể_ chạy pod.

  - Truy vấn Prometheus để lấy chỉ số CPU và bộ nhớ thời gian thực của các node tương thích.
  
  - Tính toán điểm số cho mỗi node. Điểm số là tổ hợp có trọng số giữa tài nguyên khả dụng và mức độ phù hợp với các affinity do pod định nghĩa. Các trọng số có thể cấu hình qua biến môi trường.
  
  - Chọn node tương thích có điểm số cao nhất.
  
  - Tạo `Binding` để gán pod vào node được chọn, gửi đối tượng này đến API server.
  
  - Tạo đối tượng `Event` của Kubernetes để báo cáo quyết định phân lịch thành công hoặc lỗi gặp phải, nâng cao khả năng quan sát hệ thống.

==== Prometheus Server

+ *Khái niệm:* #link("https://prometheus.io/")[Prometheus] là một bộ công cụ mã nguồn mở hỗ trợ việc giám sát và cảnh báo. Nó thu thập các chỉ số từ các mục tiêu được cấu hình theo chu kỳ, đánh giá các biểu thức rule, hiển thị kết quả và có thể kích hoạt cảnh báo.

+ *Vị trí:* Triển khai dưới dạng Deployment trong namespace `monitoring`, theo cấu hình trong `prometheus/prometheus-deployment.yaml`.

+ *Vai trò:* Thu thập, lưu trữ và cung cấp dữ liệu dạng chuỗi thời gian mô tả trạng thái các node trong cụm.

+ *Trách nhiệm trong hệ thống:*
  - Thu thập dữ liệu định kỳ từ các mục tiêu, đặc biệt là các instance *Node Exporter*.
  
  - Lưu trữ dữ liệu này trong cơ sở dữ liệu chuỗi thời gian.
  - Cung cấp API HTTP hỗ trợ ngôn ngữ PromQL. Scheduler sử dụng API này để lấy các chỉ số như `node_memory_MemAvailable_bytes` và `avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m]))`.

==== Node Exporter

+ *Tóm tắt công cụ:* #link("https://github.com/prometheus/node_exporter")[Prometheus Node Exporter] là công cụ xuất dữ liệu hệ điều hành và phần cứng dành cho hệ điều hành \*NIX, được viết bằng Go với khả năng mở rộng collector. Mục đích là cung cấp nhiều loại chỉ số của các node.

+ *Vị trí:* Triển khai dưới dạng DaemonSet, đảm bảo mỗi node đều có một instance chạy. Định nghĩa trong `node-exporter/node-exporter-daemonset.yml`.

+ *Vai trò:* Thu thập các chỉ số hệ điều hành và phần cứng chi tiết từ từng node.

+ *Trách nhiệm trong hệ thống:*
  - Thu thập dữ liệu như mức sử dụng CPU, thống kê bộ nhớ (tổng, khả dụng, cache), I/O đĩa, và lưu lượng mạng.
  
  - Cung cấp endpoint HTTP (thường là `/metrics` trên cổng 9100) để Prometheus có thể thu thập dữ liệu.

==== Kubernetes API Server

+ *Mô tả:* Thành phần cơ bản của control plane Kubernetes. Cung cấp API giao tiếp cho tất cả hoạt động trong cụm.

+ *Vai trò:* Là trung tâm quản lý cụm, lưu trữ trạng thái mong muốn và trạng thái hiện tại của tất cả đối tượng.

+ *Trách nhiệm (từ góc nhìn scheduler):*
  - Lưu trữ và quản lý trạng thái của Pod, Node, Deployment, Service, và Event.
  
  - Cung cấp cơ chế "watch" để scheduler theo dõi các pod cần được phân lịch.
  - Cung cấp các API để liệt kê node, kiểm tra thông số kỹ thuật của node và liệt kê pod đang chạy.
  - Nhận các `Binding` từ scheduler để chính thức gán pod vào node cụ thể.
  - Lưu trữ và cung cấp các `Event` phục vụ việc quan sát quá trình phân lịch.

=== Luồng tương tác tổng thể khi phân lịch một Pod

Quá trình phân lịch một pod duy nhất sử dụng scheduler tùy chỉnh tuân theo chuỗi thao tác sau:

1.  *Tạo và nhận diện Pod:* Người dùng hoặc controller gửi manifest pod đến API Server với `spec.schedulerName: custom-scheduler`. Pod ban đầu sẽ ở trạng thái `Pending`.
2.  *Phát hiện bởi Scheduler:* Scheduler phát hiện pod mới chưa được phân lịch.
3.  *Giai đoạn Predicate (Lọc):* Scheduler truy xuất danh sách node và áp dụng các kiểm tra để lọc các node tương thích:
    - Node đáp ứng yêu cầu CPU và bộ nhớ.
    
    - Node không có taint mà pod không thể tolerate.
    - Node khớp với `spec.nodeSelector` của pod.
4.  *Thu thập chỉ số (Ưu tiên):* Với các node tương thích, scheduler truy vấn Prometheus để lấy dữ liệu mới nhất như `node_memory_MemAvailable_bytes` và CPU nhàn rỗi.
5.  *Tính điểm Node:* Scheduler tính điểm tổng hợp cho mỗi node:

    - *Điểm Bộ Nhớ:* Dựa trên bộ nhớ khả dụng, chuẩn hóa.
    
    - *Điểm CPU:* Dựa trên mức nhàn rỗi của CPU, chuẩn hóa.
    - *Điểm Affinity:* 
      Nếu trong manifest của pod định nghĩa trường `preferredDuringSchedulingIgnoredDuringExecution`, các node phù hợp sẽ được cộng điểm tùy theo `weight`.
    - *Tổng điểm:* Kết hợp các điểm bằng trọng số (`SCORE_WEIGHT_MEM`, `SCORE_WEIGHT_CPU`, `SCORE_WEIGHT_AFFINITY`) qua biến môi trường.
6.  *Chọn Node:* Node có điểm cao nhất sẽ được chọn. Nếu có điểm bằng nhau, ưu tiên node có bộ nhớ hoặc CPU cao hơn.
7.  *Thao tác ràng buộc (Binding Operation):* Bộ lập lịch tùy chỉnh tạo một đối tượng `Binding` trong Kubernetes. Đối tượng này liên kết pod (dựa trên tên và namespace của nó) với node được chọn. Sau đó, `Binding` này được gửi tới *Kubernetes API Server* để chính thức gán pod vào node tương ứng.

8.  *Thực thi Pod:* Sau khi Kubernetes API Server ghi nhận `Binding`, thành phần *Kubelet* đang chạy trên node mục tiêu sẽ phát hiện pod được giao và bắt đầu quá trình kéo image, khởi tạo container, và chạy pod theo cấu hình đã định.

== Chi tiết quy trình lập lịch

Chi tiết quy trình lập lịch của bộ lập lịch Kubernetes tùy chỉnh của nhóm em là một chuỗi các hoạt động được phối hợp nhịp nhàng nhằm xác định node phù hợp nhất cho một pod đang chờ xử lý. Quá trình này được khởi xướng khi một pod được chỉ định cho bộ lập lịch này (`spec.schedulerName: custom-scheduler`) được phát hiện thông qua việc giám sát liên tục API Kubernetes. Quy trình này mạnh mẽ, tích hợp dữ liệu thời gian thực và các ưu tiên đã xác định, và có thể được chia thành nhiều giai đoạn riêng biệt: cơ chế phát hiện và theo dõi pod, giai đoạn vị từ (predicate) để lọc các node tương thích, giai đoạn tính điểm để ưu tiên các node này, giai đoạn ràng buộc (binding) để thực thi quyết định, và cuối cùng là báo cáo sự kiện toàn diện.

=== Cơ chế phát hiện và theo dõi Pod

Bước nền tảng trong chu trình lập lịch là việc xác định kịp thời và chính xác các pod thuộc phạm vi quản lý của bộ lập lịch tùy chỉnh của nhóm em. Điều này không đạt được thông qua việc thăm dò định kỳ, mà thay vào đó là một cơ chế theo dõi dựa trên sự kiện (event-driven watch mechanism) hiệu quả.

*Trách nhiệm:* Giai đoạn này chủ yếu được điều phối bởi hàm `watchUnscheduledPods` nằm trong tệp `scheduler/kubernetes.go`. Các pod được xác định bởi hàm này sau đó được tiêu thụ và xử lý bởi vòng lặp lập lịch chính trong `scheduler/main.go`.

*Phân tích cơ chế:*
1.  *Khởi tạo Kubernetes Client:* Khi khởi động, ứng dụng bộ lập lịch thiết lập một kết nối đến máy chủ API Kubernetes. Điều này được thực hiện bằng thư viện chính thức `client-go`. Hàm `initKubernetesClient` (trong `scheduler/kubernetes.go`) cố gắng sử dụng `rest.InClusterConfig()`, đây là phương thức tiêu chuẩn cho các ứng dụng chạy dưới dạng pod trong cụm Kubernetes để xác thực và kết nối với máy chủ API một cách an toàn.

2.  *Xác định Pod mục tiêu:* Bộ lập lịch tùy chỉnh của nhóm em được lập trình đặc biệt để tìm kiếm các pod thỏa mãn một tập hợp các tiêu chí chính xác, đảm bảo nó chỉ xử lý các pod dành cho logic của mình:
    - `spec.schedulerName` *phải* bằng chuỗi `"custom-scheduler"`. Giá trị này được định nghĩa là một hằng số `SchedulerName` trong `scheduler/kubernetes.go` và được tham chiếu trong toàn bộ mã nguồn và các tệp manifest Kubernetes (như `scheduler/deployments/testcustom.yaml`).
    
    - `spec.nodeName` *phải* là một chuỗi rỗng. Một trường `nodeName` rỗng biểu thị rằng hệ thống Kubernetes chưa gán pod cho bất kỳ node cụ thể nào.
    - `status.phase` *phải* là `v1.PodPending`. Trạng thái này cho biết pod đã được hệ thống Kubernetes chấp nhận nhưng đang chờ được lập lịch và thực thi sau đó.

3.  *Thiết lập theo dõi API (API Watch):* Hàm `watchUnscheduledPods` tận dụng `client-go` để thiết lập một "watch" trên các đối tượng Pod trên tất cả các không gian tên (namespaces) (`clientset.CoreV1().Pods("")`). Để tối ưu hóa điều này và giảm tải cho cả bộ lập lịch và máy chủ API, yêu cầu watch bao gồm một `fieldSelector`. Bộ chọn này, `fields.OneTermEqualSelector("spec.nodeName", "").String()`, hướng dẫn máy chủ API chỉ gửi các sự kiện cho các pod hiện chưa có node nào được gán.
    ```go
    // Đoạn mã liên quan từ scheduler/kubernetes.go minh họa thiết lập Watch
    watcher, err := clientset.CoreV1().Pods("").Watch(ctx, metav1.ListOptions{
        FieldSelector: fields.OneTermEqualSelector("spec.nodeName", "").String(),
    })
    ```
    Việc lọc phía máy chủ này rất quan trọng đối với hiệu quả trong các cụm lớn.

4.  *Logic xử lý dựa trên sự kiện:* Bộ lập lịch không thăm dò máy chủ API. Thay vào đó, nó phản ứng với các sự kiện. Khi một Pod được tạo, hoặc một Pod hiện có được sửa đổi sao cho nó khớp với tiêu chí theo dõi, máy chủ API sẽ truyền một sự kiện (ví dụ: `watch.Added` cho các pod mới, `watch.Modified` nếu một pod hiện có trở nên chưa được lập lịch và khớp với tên bộ lập lịch) đến watcher được kết nối. Mã của nhóm em lặp qua các sự kiện này trong một vòng lặp:

    - Nó ép kiểu đối tượng sự kiện thành `*v1.Pod`.

    - Sau đó, nó xác minh lại rằng `pod.Spec.SchedulerName == SchedulerName`, `pod.Spec.NodeName == ""`, và `pod.Status.Phase == v1.PodPending`. Việc kiểm tra phía máy khách này là một biện pháp bảo vệ, mặc dù bộ lọc phía máy chủ phần lớn sẽ xử lý tiêu chí `nodeName`.

5.  *Giao tiếp giữa các Goroutine qua Kênh (Channels):* Nếu một sự kiện liên quan đến một pod hoàn toàn khớp với tất cả các tiêu chí, một bản sao của đối tượng `v1.Pod` được tạo (để tránh tình trạng tranh chấp nếu đối tượng gốc trong bộ đệm watch được cập nhật) và được gửi đến một kênh Go có tên `podChannel`. Vòng lặp xử lý chính trong `scheduler/main.go` có một câu lệnh `select` liên tục lắng nghe các đối tượng `v1.Pod` mới đến trên `podChannel` này.
    ```go
    // Đoạn mã từ vòng lặp xử lý sự kiện trong scheduler/kubernetes.go
    if pod.Spec.SchedulerName == SchedulerName && pod.Spec.NodeName == "" && pod.Status.Phase == v1.PodPending {
        log.Printf("Found unscheduled pod for %s: %s/%s (Event: %s)", /* ... */)
        select {
        case podChannel <- *pod: // Gửi một bản sao
        case <-ctx.Done(): // Xử lý hủy context trong khi gửi
            // ...
            return
        }
    }
    ```
    Tương tự, các lỗi không nghiêm trọng gặp phải trong quá trình watch (ví dụ: sự cố mạng tạm thời không dẫn đến việc đóng watch) được gửi đến một kênh `errChannel` có bộ đệm kích thước 1. Vòng lặp chính cũng chọn trên kênh này để ghi lại các cảnh báo như vậy. Bộ đệm ngăn goroutine watch bị chặn nếu vòng lặp chính tạm thời bận.

6.  *Khả năng phục hồi và quản lý lỗi trong cơ chế Watch:* Cơ chế watch được thiết kế để có khả năng phục hồi:
    
    - Toàn bộ hoạt động watch được bao bọc trong một vòng lặp bên ngoài. Nếu `watcher.ResultChan()` đóng lại (điều này có thể xảy ra nếu kết nối với máy chủ API bị gián đoạn hoặc nếu phiên bản tài nguyên trở nên quá cũ, được biểu thị bằng lỗi `metav1.StatusReasonGone`), mã sẽ ghi lại sự kiện và, sau một khoảng trễ ngắn (ví dụ: 1-5 giây), cố gắng thiết lập lại một watch mới. Điều này đảm bảo rằng bộ lập lịch có thể phục hồi từ các sự cố mạng tạm thời hoặc khởi động lại máy chủ API.
    
    - Các lỗi watch cụ thể, như `http.StatusGone` (HTTP 410), kích hoạt ngay lập tức việc khởi động lại watch, vì chúng cho biết phiên bản tài nguyên của watch hiện tại không còn hợp lệ.

7.  *Ngắt hệ thống dễ dàng qua Context:* Hàm `watchUnscheduledPods`, và thực sự hầu hết các hoạt động không đồng bộ trong bộ lập lịch của nhóm em, chấp nhận một `context.Context` (tên là `ctx`). Context này được tạo trong `scheduler/main.go` và bị hủy khi ứng dụng nhận được tín hiệu tắt (SIGINT hoặc SIGTERM). Các Goroutine thường xuyên kiểm tra `ctx.Done()`. Nếu context bị hủy, chúng sẽ dọn dẹp (ví dụ: dừng watcher, đóng các kênh) và kết thúc một cách mềm mại, ngăn chặn rò rỉ tài nguyên hoặc thoát đột ngột.

Cơ chế watch dựa trên sự kiện, có khả năng phục hồi này đảm bảo rằng bộ lập lịch tùy chỉnh của nhóm em nhận biết một cách hiệu quả và kịp thời các Pod và yêu cầu của chúng.

=== Giai đoạn lọc (Predicate Phase): Lọc các Node Tương thích

Sau khi một pod chưa được lập lịch được nhận từ cơ chế watch, bộ lập lịch trước tiên phải xác định một tập hợp con các node trong cụm nơi pod *có thể* chạy một cách khả thi. Đây là giai đoạn vị từ, áp dụng một loạt các ràng buộc cứng, không thể thương lượng. Chỉ những node thỏa mãn tất cả các kiểm tra vị từ mới được chuyển sang giai đoạn tính điểm tiếp theo.

*Trách nhiệm:* Logic lọc quan trọng này chủ yếu được đóng gói trong hàm `predicateChecks` trong `scheduler/kubernetes.go`. Hàm này được hỗ trợ bởi một số hàm trợ giúp như `calculateNodeUsage`, `calculatePodResourceRequests`, `checkNodeResources`, và `checkNodeTaints`.

*Phân tích cơ chế:*
Hàm `predicateChecks` đánh giá một cách có hệ thống từng node trong cụm (hoặc một danh sách đã được lọc trước dựa trên `pod.Spec.NodeName` hoặc `pod.Spec.NodeSelector`) dựa trên các yêu cầu của pod cần lập lịch.

1.  *Tạo danh sách Node ứng cử viên ban đầu:*

    - *Yêu cầu Node rõ ràng (`pod.Spec.NodeName`):* Nếu đặc tả của pod bao gồm một `nodeName` không rỗng, giai đoạn vị từ chỉ xem xét node được chỉ định *này*. Nếu node này không vượt qua bất kỳ kiểm tra nào sau đó, pod không thể được lập lịch bởi bộ lập lịch này.
    
    - *Bộ chọn Node (`pod.Spec.NodeSelector`):* Nếu `pod.Spec.NodeSelector` (một map các cặp khóa-giá trị) được định nghĩa, bộ lập lịch chỉ liệt kê những node có nhãn khớp với tất cả các mục trong `NodeSelector`. Điều này đạt được bằng cách chuyển đổi `MatchLabels` thành một `labels.Selector` và sử dụng nó trong `ListOptions` của `client-go`.
    
    - *Trường hợp mặc định:* Nếu cả `nodeName` và `nodeSelector` đều không được chỉ định, tất cả các node trong cụm ban đầu được coi là ứng cử viên.

2.  *Trạng thái Node không thể lập lịch (`node.Spec.Unschedulable`):*
    - Trường `Unschedulable` của mỗi node ứng cử viên được kiểm tra. Nếu trường boolean này là `true`, nó biểu thị rằng một quản trị viên đã cách ly (cordon) node, với ý định không cho nó nhận các pod mới. Các node như vậy thường bị loại trừ bởi các vị từ, và bộ lập lịch của nhóm em tuân thủ quy ước này.

3.  *Kiểm tra tính sẵn có của Tài nguyên (CPU và Bộ nhớ):* Đây là một quy trình nhiều bước để đảm bảo node có đủ tài nguyên.

    - *Tính toán nhu cầu tài nguyên của Pod:* Hàm trợ giúp `calculatePodResourceRequests` lặp qua tất cả các container được định nghĩa trong `pod.Spec.Containers`. Đối với mỗi container, nó cộng các giá trị được chỉ định trong `container.Resources.Requests[v1.ResourceCPU]` và `container.Resources.Requests[v1.ResourceMemory]`. Chúng đại diện cho lượng CPU (tính bằng cores/millicores) và bộ nhớ (tính bằng byte) mà pod đảm bảo cần. Kết quả là các đối tượng `resource.Quantity`, hỗ trợ các phép tính số học cho các giá trị tài nguyên (ví dụ: "500m" cho CPU, "1Gi" cho bộ nhớ).
    
    - *Tính toán mức sử dụng hiện tại của Node:* Hàm trợ giúp `calculateNodeUsage` xác định các tài nguyên đã được cam kết trên một node ứng cử viên. Nó liệt kê tất cả các pod hiện đang được gán cho node đó (tức là `existingPod.Spec.NodeName == node.Name`) mà không ở trạng thái cuối (Failed hoặc Succeeded). Đối với mỗi pod hiện có như vậy, nó cộng dồn các `requests` CPU và bộ nhớ của các container của chúng. Tổng này đại diện cho tổng tài nguyên được yêu cầu bởi các pod đã có trên node đó.
    
    - *So sánh nhu cầu của Pod với tài nguyên khả dụng của Node:* Hàm trợ giúp `checkNodeResources` thực hiện so sánh cuối cùng. Nó sử dụng `node.Status.Allocatable`, đại diện cho lượng tài nguyên trên một node có sẵn cho các pod (sau khi tính đến các daemon hệ thống và tài nguyên dành riêng cho kubelet).
    
        - `availableCPUOnNode = node.Status.Allocatable.Cpu() - currentTotalCPURequestsOnNode`
        
        - `availableMemoryOnNode = node.Status.Allocatable.Memory() - currentTotalMemoryRequestsOnNode`
        
        - Pod chỉ có thể được lập lịch nếu thỏa mãn đồng thời 2 tiêu chí `newPodCPURequest <= availableCPUOnNode` (có đủ CPU) và `newPodMemoryRequest <= availableMemoryOnNode` (có đủ bộ nhớ).
        
        - Các phép so sánh và trừ được thực hiện bằng các phương thức được cung cấp bởi kiểu `resource.Quantity`, đảm bảo xử lý chính xác các đơn vị tài nguyên.

4.  *Khả năng tương thích giữa Taint và Toleration:* Kiểm tra này đảm bảo rằng pod có thể chịu đựng bất kỳ hạn chế nào (taint) được đặt trên node.

    - Hàm trợ giúp `checkNodeTaints` lặp qua từng `v1.Taint` trong `node.Spec.Taints`.

    - Đối với mỗi taint, nó kiểm tra `Effect` của nó:
    
        - Nếu effect là `v1.TaintEffectNoSchedule` hoặc `v1.TaintEffectNoExecute`, bộ lập lịch phải tìm một `v1.Toleration` tương ứng trong `pod.Spec.Tolerations`.
        
        - Hàm trợ giúp `tolerationsTolerateTaint` (bên trong sử dụng `toleration.ToleratesTaint()`) kiểm tra xem bất kỳ toleration nào của pod có "khớp" với taint không. Một sự khớp thường có nghĩa là:
    
            - `Key` khớp (hoặc toleration không có key, khớp với tất cả các key).
            
            - `Operator` là `v1.TolerationOpExists` (khớp với bất kỳ giá trị nào cho key), hoặc `Operator` là `v1.TolerationOpEqual` và `Value` cũng khớp.
            
            - `Effect` của toleration khớp với effect của taint (hoặc toleration không có effect nào được chỉ định, khớp với tất cả các effect).
            
        - Nếu một taint `NoSchedule` hoặc `NoExecute` được tìm thấy trên node mà pod không có toleration tương ứng, node đó không vượt qua kiểm tra vị từ.
        
    - *Xử lý trì hoãn các Taint `PreferNoSchedule`:* Quan trọng là, nếu một taint có effect `v1.TaintEffectPreferNoSchedule`, giai đoạn vị từ của bộ lập lịch của nhóm em *không* lọc bỏ node đó. Loại taint này cho biết một sự ưu tiên, không phải là một ràng buộc cứng. Các node như vậy được chuyển đến giai đoạn tính điểm, nơi chúng có thể nhận điểm thấp hơn do sự ưu tiên này, nhưng vẫn có thể được chọn nếu không có node tương thích, không bị taint nào tốt hơn.

5.  *Yêu cầu Node Affinity/Anti-Affinity:*
    - Mặc dù trọng tâm chính của bộ lập lịch của nhóm em đối với affinity là `preferredDuringSchedulingIgnoredDuringExecution` (được xử lý trong giai đoạn tính điểm), một giai đoạn vị từ đầy đủ cũng sẽ đánh giá `requiredDuringSchedulingIgnoredDuringExecution` từ `pod.Spec.Affinity.NodeAffinity`. Điều này sẽ hoạt động giống như một dạng biểu cảm hơn của `nodeSelector`, nơi các node phải khớp với các biểu thức nhãn phức tạp để vượt qua. Việc triển khai hiện tại của nhóm em ngầm bao gồm việc khớp nhãn đơn giản thông qua `pod.Spec.NodeSelector`.

*Kết quả Giai đoạn Lọc và Báo cáo Sự kiện:*
- Nếu một node vượt qua thành công tất cả các kiểm tra vị từ ở trên, nó được thêm vào danh sách "các node tương thích".

- Nếu, sau khi đánh giá tất cả các node ứng cử viên, danh sách các node tương thích này trống, điều đó có nghĩa là pod không thể được lập lịch trên bất kỳ node nào trong cụm dựa trên các yêu cầu cứng của nó. Trong trường hợp này, `predicateChecks` trả về một lỗi.

- Hàm gọi (thường là `schedulePod` trong `scheduler/processor.go`) sau đó sẽ sử dụng `postEvent` (từ `scheduler/kubernetes.go`) để tạo một `Event` Kubernetes liên quan đến pod. Sự kiện này sẽ có:

    - `Reason`: "FailedScheduling"

    - `Type`: "Warning"
    
    - `Message`: Một thông báo mô tả, ví dụ: "pod (namespace/pod-name) không vượt qua kiểm tra vị từ trên tất cả các node. Không đủ CPU trên node-X; Pod không chịu được taint Y trên node-Z." Điều này cung cấp cho quản trị viên lý do rõ ràng cho việc lập lịch thất bại.

Chỉ những node xuất hiện từ giai đoạn vị từ nghiêm ngặt này mới được coi là ứng cử viên khả thi cho giai đoạn tính điểm tinh tế hơn tiếp theo.

=== Giai đoạn tính điểm (Scoring Phase): Ưu tiên các Node

Sau khi giai đoạn vị từ đã tạo ra một danh sách các node tương thích (tức là các node nơi pod *có thể* chạy), giai đoạn tính điểm, còn được gọi là giai đoạn ưu tiên hóa, sẽ xếp hạng các node này từ phù hợp nhất đến ít phù hợp nhất. Đây là nơi trí tuệ cốt lõi của bộ lập lịch tùy chỉnh của nhóm em phát huy tác dụng, vì nó kết hợp các số liệu thời gian thực và các ưu tiên đã xác định để đưa ra lựa chọn tối ưu.

*Trách nhiệm:* Logic tính điểm cốt lõi được triển khai trong hàm `ScoreNodes` và các hàm trợ giúp liên quan của nó trong `scheduler/scoring.go`. Hàm `getBestNode` trong `scheduler/getBestNode.go` đóng vai trò trung gian, gọi `ScoreNodes` với các node tương thích và chi tiết pod. Hoạt động của giai đoạn này bị ảnh hưởng đáng kể bởi struct `ScoringConfig` (chứa `WeightMem`, `WeightCPU`, `WeightAffinity`), được điền vào trong `scheduler/main.go` bằng cách đọc các biến môi trường (ví dụ: `SCORE_WEIGHT_MEM`) được định nghĩa trong tệp YAML triển khai của bộ lập lịch (`scheduler/custom-scheduler-deployment.yaml`).

*Phân tích cơ chế:*

1.  *Thu thập số liệu Node trong thời gian thực từ Prometheus:* Đây là bước quan trọng đầu tiên trong việc tính điểm, vì nó cung cấp dữ liệu đồng thời gian thực.

    - *Hàm:* `WorkspaceNodeMetrics` (trong `scheduler/scoring.go`) chịu trách nhiệm. Nó chấp nhận một map các tên node tương thích để đảm bảo số liệu chỉ được lấy và xử lý cho các node liên quan.
    
    - *Điểm cuối Prometheus (Prometheus Endpoint):* Nó nhắm mục tiêu dịch vụ Prometheus, có địa chỉ được xác định bởi hằng số `prometheusService` (ví dụ: `http://prometheus-service.monitoring.svc.cluster.local:8080`, được cấu hình để trỏ đến `prometheus-service` trong không gian tên `monitoring`).
    
    - *Các truy vấn PromQL Cụ thể:* Bộ lập lịch của nhóm em sử dụng các truy vấn PromQL chính xác để lấy dữ liệu tài nguyên có ý nghĩa:
    
        - *Bộ nhớ khả dụng:* Truy vấn: `node_memory_MemAvailable_bytes` (từ hằng số `memPromQL`). Số liệu này được ưu tiên hơn `node_memory_MemFree_bytes` vì `MemAvailable` cung cấp ước tính bộ nhớ có sẵn để khởi chạy ứng dụng mới, không cần swap, và bao gồm cả slab memory có thể thu hồi. Đây là một chỉ số chính xác hơn về tính sẵn có thực tế từ góc độ của kernel.
        
        - *Trung bình số core CPU "rảnh":* Truy vấn được sử dụng:`avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m]))` (từ hằng số `cpuIdlePromQL`). Truy vấn này tính toán:
        
            - `node_cpu_seconds_total{mode="idle"}`: Một bộ đếm tổng thời gian (tính bằng giây) CPU đã ở trạng thái rảnh, trên mỗi lõi CPU.
            
            - `rate(...[1m])`: Tính toán tốc độ tăng trung bình mỗi giây của bộ đếm này trong 1 phút qua. Điều này thực chất cho biết tỷ lệ thời gian mỗi lõi CPU rảnh trong phút đó (ví dụ: 0.5 có nghĩa là 50% rảnh).
            
            - `avg by (instance) (...)`: Tính trung bình các tỷ lệ rảnh trên mỗi lõi này trên tất cả các lõi của một node nhất định (được xác định bằng nhãn `instance`), cho ra một giá trị đại diện cho số lượng lõi "tương đương rảnh" trung bình trên node đó. Ví dụ, trên một node 8 lõi, giá trị 4.0 từ truy vấn này có nghĩa là, trung bình, có 4 lõi CPU rảnh trong phút vừa qua.
            
    - *Thực thi truy vấn:* Hàm trợ giúp `queryPrometheus` xử lý yêu cầu HTTP GET thực tế đến điểm cuối `/api/v1/query` của Prometheus. Nó đảm bảo mã hóa URL đúng cách cho chuỗi truy vấn PromQL. Nó mong đợi một phản hồi JSON và giải mã nó thành các struct Go `MetricResponse`, `Data`, và `Result`, được định nghĩa trong `scheduler/scoring.go` để khớp với cấu trúc phản hồi API của Prometheus.
    
    - *Ánh xạ số liệu Prometheus tới Node của Kubernetes:* Số liệu Prometheus thường sử dụng nhãn `instance` (ví dụ: `node-exporter-ip:port`). Hệ thống của nhóm em cần ánh xạ điều này tới tên node Kubernetes. Hàm `getNodeNameFromMetric`, cùng với `parseInstanceLabel`, xử lý việc này. Đối với các số liệu bắt nguồn từ `node-exporter` (chạy dưới dạng DaemonSet), cấu hình scrape của Prometheus trong `prometheus/config-map.yaml` (cụ thể là job `kubernetes-pods` khám phá `node-exporter`) sử dụng các quy tắc gán lại nhãn (relabeling). Các quy tắc này lấy `__meta_kubernetes_pod_node_name` (tên node Kubernetes nơi pod `node-exporter` đang chạy) và đặt nó làm nhãn `instance` trên các số liệu được scrape. Do đó, nhãn `instance` trực tiếp cung cấp tên node Kubernetes. `parseInstanceLabel` cũng xử lý việc loại bỏ hậu tố cổng nếu có.
    
    - *Phân tích giá trị số liệu:* Prometheus trả về các giá trị số liệu dưới dạng một cặp: `[<timestamp>, "<value_string>"]`. Hàm trợ giúp `parseMetricValue` trích xuất `"<value_string>"` và chuyển đổi nó thành `float64` để tính toán.
    
    - *Khả năng phục hồi trong việc lấy số liệu:* `WorkspaceNodeMetrics` được thiết kế để có phần nào khả năng phục hồi. Nếu việc lấy số liệu cho một loại (ví dụ: bộ nhớ) thất bại, nhưng số liệu CPU thành công, nó sẽ ghi lại một cảnh báo và tiếp tục. Điểm số cho loại số liệu bị lỗi sẽ thực chất bằng không cho tất cả các node. Tuy nhiên, nếu *tất cả* việc lấy số liệu đều thất bại (cả bộ nhớ và CPU đều trả về lỗi hoặc không có dữ liệu cho các node tương thích), `WorkspaceNodeMetrics` sẽ trả về một lỗi, sau đó `ScoreNodes` sẽ truyền đi, thường dẫn đến thất bại trong việc lập lịch hoặc phương án dự phòng. Hệ thống hiện tại không có xử lý tinh vi cho độ trễ của Prometheus ngoài các timeout HTTP tiêu chuẩn, đây là một lĩnh vực tiềm năng để cải tiến trong tương lai.

2.  *Tính toán các thành phần điểm riêng lẻ cho mỗi node tương thích:* Sau khi lấy số liệu, mỗi node tương thích được tính điểm trên nhiều khía cạnh:

    - *Tính toán điểm bộ nhớ:*
        - Giá trị thô `node_memory_MemAvailable_bytes` cho node được lấy.
        - Giá trị thô này sau đó được chuyển cho hàm chuẩn hóa`normalizeScore(value, maxValue)`. Giá trị `maxValue` ở đây là giá trị `MemAvailable` cao nhất được quan sát trên *tất cả* các node tương thích mà số liệu bộ nhớ đã được truy xuất thành công.
        - `normalizeScore` tính toán `(value / maxValue) * 10`. Điều này điều chỉnh tính sẵn có của bộ nhớ theo thang điểm 0-10. Một node có nhiều bộ nhớ khả dụng nhất sẽ nhận được điểm 10 (hoặc gần bằng), trong khi một node có rất ít (hoặc thiếu dữ liệu, dẫn đến `value = 0`) sẽ nhận điểm 0. Chuẩn hóa là rất quan trọng vì nó đưa các số liệu khác nhau (byte bộ nhớ, số lõi CPU) về một thang đo chung, có thể so sánh được trước khi áp dụng trọng số. Thang điểm 0-10 là một quy ước phổ biến trong việc tính điểm của bộ lập lịch Kubernetes.
        
    - *Tính toán điểm CPU:*
        - Giá trị số lõi CPU rảnh trung bình thô cho node được sử dụng.
        
        - Giá trị này cũng được chuẩn hóa tương tự bằng cách sử dụng `normalizeScore(value, maxValue)`, trong đó `maxValue` là giá trị số lõi CPU rảnh trung bình cao nhất được quan sát trong số các node tương thích. Điều này cũng cho kết quả là một điểm số 0-10.
        
    - *Tính toán điểm Node Affinity:*
    
        - Hàm `calculateAffinityScore(node, pod)` được gọi. Hàm này kiểm tra trường `preferredDuringSchedulingIgnoredDuringExecution` trong `pod.Spec.Affinity.NodeAffinity`. Trường này chứa một danh sách các cấu trúc giống như `WeightedPodAffinityTerm`, mỗi cấu trúc có một `weight` (số nguyên từ 1-100) và một `preference` (một `NodeSelectorTerm`).
        
        - Đối với mỗi `preferredTerm` trong danh sách:
            - Nếu `preference.MatchExpressions` được định nghĩa, các biểu thức này (ví dụ: `key: zone, operator: In, values: [a, b]`) được chuyển đổi thành một đối tượng `labels.Selector` bằng cách sử dụng hàm trợ giúp `NodeSelectorRequirementsAsSelector` (tận dụng package sẵn có của Kubernetes `k8s.io/apimachinery/pkg/labels` và `k8s.io/apimachinery/pkg/selection`).
            
            - `labels.Selector` này sau đó được đánh giá dựa trên `node.Labels`.
            
            - Nếu nhãn của node thỏa mãn bộ chọn cho thuật ngữ ưu tiên đó, `weight` của thuật ngữ đó được thêm vào biến `totalPreferenceScore` đang chạy cho node đó.
            
        - Sau khi đánh giá tất cả các thuật ngữ ưu tiên, `totalPreferenceScore` (có thể dao động từ 0 đến 100 lần số lượng thuật ngữ) được điều chỉnh theo thang điểm 0-10. Logic hiện tại của nhóm em điều chỉnh điều này bằng cách giả định điểm thô tối đa mong muốn là 100 tương ứng với 10: 
          ```go
          scaledScore = (float64(totalPreferenceScore) / 100.0) * float64(maxScoreConstant)
          ``` 
          `maxScoreConstant` này là 10. Kết quả được giới hạn trong khoảng 0 và 10. Việc điều chỉnh này có nghĩa là `SCORE_WEIGHT_AFFINITY` hoạt động như một hệ số nhân trên thành phần affinity cơ sở 0-10, làm cho tác động của nó trở nên trực quan hơn.

3.  *Kết hợp các điểm riêng lẻ thành tổng điểm theo trọng số tương ứng:*
    - Struct `ScoringConfig`, lưu các trọng số của từng loại điểm, được trích xuất từ các biến môi trường (ví dụ: `SCORE_WEIGHT_MEM: "0.6"`, `SCORE_WEIGHT_CPU: "0.4"` và `SCORE_WEIGHT_AFFINITY: "1.0"` trong tệp manifest `scheduler/custom-scheduler-deployment.yaml`).
    
    - Đối với mỗi node, `TotalScore` được tính bằng tổng có trọng số:
      ```go
      nodeScore.TotalScore = 
        (config.WeightMem * nodeScore.MemScore) 
        + (config.WeightCPU * nodeScore.CPUScore) 
        + (config.WeightAffinity * nodeScore.AffinityScore);
      ```
    - Kết quả, cùng với các điểm thành phần và tên node, được lưu trữ trong một struct `NodeScore` (được định nghĩa trong `scheduler/scoring.go`).

4.  *Chọn node tốt nhất dựa trên tổng điểm:*
    - Gồm một danh sách các đối tượng `NodeScore`, điểm tương ứng cho mỗi node sau khi tính toán thành công.
    
    - Danh sách này sau đó được sắp xếp. Khóa sắp xếp chính là `TotalScore` theo thứ tự giảm dần (điểm cao hơn thì tốt hơn).
    
    - *Tie-breaking:* Nếu hai hoặc nhiều node có cùng `TotalScore` chính xác, một cơ chế tie-breaking được áp dụng để đảm bảo lựa chọn là xác định (deterministic):
        1.  Node có `MemScore` cao hơn được ưu tiên. (Lý do: Bộ nhớ thường là tài nguyên quan trọng hơn, ít bị nén hơn CPU trong nhiều khối lượng công việc).
        
        2.  Nếu `MemScore` cũng hòa, node có `CPUScore` cao hơn được ưu tiên.
        
    - Node đứng đầu danh sách đã sắp xếp này được chỉ định là "node tốt nhất" cho Pod.

*Kết quả Tính điểm và Phương án Dự phòng:*
- Hàm `ScoreNodes` trả về `Name` của node tốt nhất này.

- Nếu, vì một lý do nào đó, `ScoreNodes` thất bại (ví dụ: tất cả các lần lấy số liệu đều thất bại một cách thảm khốc) nhưng giai đoạn vị từ *đã* trả về các node tương thích, hàm `schedulePod` (trong `scheduler/processor.go`) sẽ triển khai một phương án dự phòng đơn giản: nó ghi lại lỗi tính điểm và cố gắng lập lịch pod trên node *đầu tiên* từ danh sách tương thích. Đây là một lưới an toàn để ngăn một pod không được lập lịch vô thời hạn nếu việc tính điểm gặp sự cố không mong muốn, mặc dù mục tiêu luôn là để việc tính điểm thành công.

Giai đoạn tính điểm chi tiết này cho phép bộ lập lịch của nhóm em phân biệt chi tiết giữa các node khả thi, vượt ra ngoài việc đáp ứng yêu cầu tài nguyên đơn giản để xem xét tính sẵn có thực tế và các ưu tiên do khối lượng công việc xác định.

=== Giai đoạn ràng buộc (Binding Phase): Gán Pod cho Node

Sau khi giai đoạn tính điểm đã xác định một cách dứt khoát node tốt nhất duy nhất cho pod, hành động cuối cùng là cam kết quyết định này bằng cách gán chính thức pod cho node đó trong cụm Kubernetes. Điều này được thực hiện thông qua quy trình "ràng buộc".

*Trách nhiệm:* Bước quan trọng này được thực hiện bởi hàm `bindPod`, nằm trong `scheduler/kubernetes.go`.

*Phân tích cơ chế:*
1.  *Khái niệm về đối tượng `Binding`:* Trong Kubernetes, các bộ lập lịch thường không trực tiếp sửa đổi trường `spec.nodeName` của đối tượng Pod mà chúng đang lập lịch. Thay vào đó, cơ chế ưu tiên là tạo một đối tượng API riêng biệt có `Kind: Binding`. Đối tượng `Binding` này hoạt động như một chỉ thị cho máy chủ API Kubernetes, hướng dẫn nó gán một pod cụ thể cho một node cụ thể. Cách tiếp cận này duy trì sự tách biệt rõ ràng về trách nhiệm: bộ lập lịch đề xuất một ràng buộc, và máy chủ API thực thi nó.

2.  *Xây dựng đối tượng `v1.Binding`:* Hàm `bindPod` của nhóm em xây dựng một đối tượng `v1.Binding` một cách tỉ mỉ.
    - `ObjectMeta.Name`: Được đặt thành `name` của `podToSchedule`.
    
    - `ObjectMeta.Namespace`: Được đặt thành `namespace` của `podToSchedule`. Ràng buộc phải được tạo trong cùng không gian tên với pod.
    
    - `ObjectMeta.Annotations`: Một chú thích quan trọng cần để ý là `kubernetes.io/custom-scheduler: SchedulerName` (trong đó `SchedulerName` là "`custom-scheduler`"), được thêm vào. Điều này đóng vai trò như một bản ghi, có thể xem được qua `kubectl describe binding <pod-name>`, cho biết bộ lập lịch nào đã đưa ra quyết định ràng buộc cụ thể này.
    
    - `Target`: Đây là phần cốt lõi của ràng buộc. Nó là một `v1.ObjectReference` xác định duy nhất node mà pod sẽ được ràng buộc.
        - `Target.APIVersion`: Đặt thành "v1".
        - `Target.Kind`: Đặt thành "Node".
        - `Target.Name`: Đặt thành `nodeName`, là tên của node tốt nhất được xác định bởi giai đoạn tính điểm.
    ```go
    // Minh họa cấu trúc từ scheduler/kubernetes.go
    binding := &v1.Binding{
        ObjectMeta: metav1.ObjectMeta{
            Name:      podToSchedule.Name,
            Namespace: podToSchedule.Namespace,
            Annotations: map[string]string{
                "kubernetes.io/custom-scheduler": SchedulerName, // "custom-scheduler"
            },
        },
        Target: v1.ObjectReference{
            APIVersion: "v1",
            Kind:       "Node",
            Name:       nodeName, // Tên của node tốt nhất
        },
    }
    ```

3.  *Thực thi lệnh gọi API Bind:* Bộ lập lịch sau đó sử dụng `clientset` `client-go` của mình để thực hiện một yêu cầu POST đến máy chủ API Kubernetes để tạo đối tượng `Binding` này. Đường dẫn API cụ thể cho việc này là một tài nguyên con của API Pods:
    
  ```go
  err := clientset.CoreV1().Pods(podToSchedule.Namespace).Bind(ctx, binding, metav1.CreateOptions{})
  ```
    
    - `ctx` (context) được truyền cho lệnh gọi này, cho phép nó bị hủy nếu bộ lập lịch đang tắt.
    
    - `metav1.CreateOptions{}` được sử dụng vì không cần tùy chọn tạo đặc biệt nào.

4.  *Vai trò của Máy chủ API trong việc Binding:* Sau khi nhận và xác thực thành công đối tượng `Binding`, máy chủ API Kubernetes thực hiện việc gán thực tế: nó cập nhật trường `spec.nodeName` của đối tượng `v1.Pod` gốc (được xác định bởi `binding.ObjectMeta.Name` và `binding.ObjectMeta.Namespace`) thành giá trị của `binding.Target.Name`. Khi `spec.nodeName` được đặt, pod được coi là đã được lập lịch.

5.  *Kích hoạt Kubelet:* Thành phần Kubelet chạy trên node vừa được gán (tức là node có tên khớp với `spec.nodeName` đã cập nhật của pod) đang theo dõi máy chủ API để tìm các pod được gán cho nó. Khi thấy pod này xuất hiện trong danh sách của mình, nó sẽ tiếp quản trách nhiệm vòng đời của pod trên node đó: kéo các image container cần thiết, tạo sandbox cho container, chạy container, thiết lập mạng và gắn kết volume.

6.  *Xử lý lỗi Binding:* Lệnh gọi API `Bind` có thể thất bại vì nhiều lý do (ví dụ: pod đã bị xóa ngay trước khi ràng buộc, sự cố mạng, lỗi máy chủ API, hoặc, ít phổ biến hơn đối với ràng buộc, xung đột tương tranh lạc quan (optimistic concurrency conflicts) nếu một thực thể khác cố gắng cập nhật pod đồng thời, mặc dù điều này hiếm khi xảy ra đối với việc gán `nodeName` thông qua ràng buộc).

    - Nếu `err != nil` từ lệnh gọi `Bind`, hàm `bindPod` của nhóm em sẽ ghi lại một thông báo lỗi chi tiết.

    - Sau đó, nó gọi hàm `postEvent()` để tạo một `Event` Kubernetes với `Reason: "FailedBinding"` và `Type: "Warning"`, bao gồm cả thông báo lỗi. Điều này làm cho lỗi có thể nhìn thấy được đối với quản trị viên. Lỗi sau đó được truyền lên hàm `schedulePod`.

7.  *Báo cáo thành công:* Nếu lệnh gọi `Bind` thành công (`err == nil`), `bindPod` sẽ ghi lại thành công và gọi `postEvent` để tạo một `Event` "Scheduled" (Type: "Normal") cho pod, xác nhận rằng bộ lập lịch tùy chỉnh của nhóm em đã gán thành công nó cho node đã chọn.

Do đó, giai đoạn ràng buộc là hành động quyết định chuyển đổi quyết định đã tính toán của bộ lập lịch thành một vị trí pod thực tế trong cụm Kubernetes.

=== Báo cáo sự kiện

Để đảm bảo tính minh bạch và hỗ trợ gỡ lỗi cũng như giám sát hoạt động, bộ lập lịch tùy chỉnh của nhóm em chủ động tạo ra các đối tượng `Event` của Kubernetes tại các điểm chính khác nhau trong quy trình làm việc của nó. Các sự kiện này cung cấp một bản ghi theo trình tự thời gian về các hành động và quyết định của bộ lập lịch liên quan đến các pod cụ thể.

*Trách nhiệm:* Việc tạo và đăng các sự kiện này được tập trung trong hàm `postEvent` bên trong tệp `scheduler/kubernetes.go`.

*Phân tích cơ chế:*
Hàm `postEvent` được gọi với các tham số chỉ định pod liên quan, một mã `reason` (lý do), một `message` (thông báo) mà con người có thể đọc được, và một `eventType` (loại sự kiện) ("Normal" hoặc "Warning").

1.  *Xây dựng đối tượng `v1.Event`:* Một đối tượng `v1.Event` được xây dựng tỉ mỉ với các trường sau:
    - `ObjectMeta.GenerateName`: Đặt thành `pod.Name + "-"`. Điều này hướng dẫn máy chủ API tạo một tên duy nhất cho sự kiện, thường bằng cách nối thêm một hậu tố ngẫu nhiên, điều này cần thiết vì nhiều sự kiện có thể được liên kết với cùng một pod.
    
    - `ObjectMeta.Namespace`: Đặt thành `pod.Namespace`, vì các sự kiện là các đối tượng thuộc không gian tên (namespaced) và nên nằm trong cùng không gian tên với đối tượng mà chúng liên quan đến.
    
    - `InvolvedObject`: Trường quan trọng này là một `v1.ObjectReference` liên kết trực tiếp sự kiện với pod đang được lập lịch. Nó bao gồm:
        - `Kind: "Pod"`
        - `Namespace: pod.Namespace`
        - `Name: pod.Name`
        - `UID: pod.UID` (ID duy nhất của instance pod)
        - `APIVersion: "v1"`
        - `ResourceVersion: pod.ResourceVersion` (Liên kết sự kiện với một phiên bản cụ thể của đối tượng pod, hỗ trợ gỡ lỗi nếu đặc tả pod thay đổi).
    
    - `Reason`: Một chuỗi ngắn gọn, máy có thể đọc được cho biết bản chất của sự kiện (ví dụ: "Scheduled", "FailedScheduling", "FailedBinding"). Những lý do này có thể được sử dụng để lọc các sự kiện.
    
    - `Message`: Một giải thích chi tiết hơn, con người có thể đọc được về những gì đã xảy ra. Ví dụ, đối với sự kiện "FailedScheduling", thông báo có thể liệt kê các lỗi vị từ cụ thể.
    
    - `Source`: Một đối tượng `v1.EventSource` xác định thành phần đã tạo ra sự kiện.
        - `Component`: Đặt thành `SchedulerName` (tức là "custom-scheduler").
    
    - `FirstTimestamp` và `LastTimestamp`: Cả hai đều được đặt thành `metav1.Now()` tại thời điểm tạo sự kiện, vì mỗi lệnh gọi đến `postEvent` tạo ra một instance sự kiện riêng biệt.
    
    - `Count`: Đặt thành `1`.
    
    - `Type`: Đặt thành `"Normal"` (cho các sự kiện thông tin như lập lịch thành công) hoặc `"Warning"` (cho các lỗi hoặc thất bại).
    
    - `ReportingController`: Đặt thành `SchedulerName`. Trường này, cùng với `ReportingInstance`, hữu ích cho việc quy trách nhiệm sự kiện khi nhiều bộ điều khiển (controller) có thể đang hoạt động trên các đối tượng.
    
    - `ReportingInstance`: Đặt thành tên của pod của chính bộ lập lịch. Thông tin này được lấy từ biến môi trường `POD_NAME`, được đưa vào pod của bộ lập lịch bằng cách sử dụng Downward API (như được cấu hình trong `scheduler/custom-scheduler-deployment.yaml` thông qua `valueFrom: fieldRef: fieldPath: metadata.name`). Điều này xác định chính xác instance nào của bộ lập lịch đã tạo ra sự kiện, đặc biệt hữu ích nếu chạy nhiều bản sao (replica) (mặc dù việc triển khai hiện tại của nhóm em sử dụng một bản sao).

2.  *Đăng sự kiện lên máy chủ API:*
    - Đối tượng `v1.Event` đã được xây dựng sau đó được tạo trong không gian tên của pod sử dụng `clientset` của `client-go`:
      ```go
      clientset.CoreV1().Events(pod.Namespace).Create(eventCtx, event, metav1.CreateOptions{})
      ```
      
    - Một `eventCtx` với thời gian chờ ngắn (ví dụ: 10 giây) được sử dụng cho lệnh gọi API này để ngăn bộ lập lịch bị treo vô thời hạn nếu việc tạo sự kiện gặp sự cố.
    
    - Nếu việc tạo sự kiện thất bại (ví dụ: do tải máy chủ API hoặc sự cố mạng), một cảnh báo được ghi lại bởi bộ lập lịch, nhưng lỗi này thường không làm dừng quy trình lập lịch chính cho chính pod đó. Mục tiêu chính là lập lịch cho pod; việc báo cáo sự kiện là thứ yếu, mặc dù quan trọng đối với khả năng quan sát.

*Mục đích và Tiện ích của Sự kiện:*
- *Gỡ lỗi:* Khi một pod không thể lập lịch, `kubectl describe pod <pod-name>` sẽ hiển thị các sự kiện này, thường cung cấp lý do chính xác (ví dụ: "0/3 nodes are available: 3 Insufficient cpu").

- *Giám sát:* Quản trị viên cụm có thể theo dõi hoặc truy vấn các sự kiện để giám sát tình trạng và hành vi của bộ lập lịch tùy chỉnh.

- *Dấu vết Kiểm toán:* Các sự kiện đóng vai trò như một bản ghi lịch sử về các quyết định lập lịch.

Bằng cách báo cáo nhất quán các hành động của mình, bộ lập lịch tùy chỉnh của nhóm em tích hợp tốt với các thực tiễn quan sát tiêu chuẩn của Kubernetes, giúp cho hành vi của nó dễ hiểu và có thể chẩn đoán được.

== Cấu trúc mã nguồn tổng thể và các phần chính

Dự án bộ lập lịch Kubernetes tùy chỉnh của nhóm em được tổ chức thành nhiều tệp Go trong thư mục `scheduler/`, cùng với các tệp manifests YAML Kubernetes hỗ trợ trong các thư mục con chuyên dụng. Cấu trúc này thúc đẩy tính mô-đun hóa và tách biệt các mối quan tâm (separation of concerns), giúp mã nguồn dễ quản lý và dễ hiểu hơn. Ngôn ngữ triển khai chính là Go, sử dụng thư viện `client-go` chính thức của Kubernetes để tương tác API.

=== Logic ứng dụng chính (`scheduler/`)

Các tệp ứng dụng Go chính nằm trực tiếp trong thư mục `scheduler/`:

- `main.go`:
    + *Vai trò:* Tệp này đóng vai trò là điểm vào (entry point) cho ứng dụng bộ lập lịch tùy chỉnh.
    
    + *Trách nhiệm chính:*
        - Khởi tạo ứng dụng, bao gồm thiết lập ghi log.
        
        - Phân tích các đối số dòng lệnh hoặc biến môi trường để cấu hình. Quan trọng là, nó gọi `loadScoringConfig` để đọc các trọng số tính điểm (ví dụ: `SCORE_WEIGHT_MEM`, `SCORE_WEIGHT_CPU`, `SCORE_WEIGHT_AFFINITY`) từ các biến môi trường.
        
        - Khởi tạo Kubernetes `clientset` của `client-go` thông qua `initKubernetesClient`, hàm này cố gắng cấu hình trong cụm (in-cluster).
        
        - Thiết lập xử lý tín hiệu (cho SIGINT, SIGTERM) để cho phép tắt mềm mại (graceful shutdown) bằng cách sử dụng `context.Context`.
        
        - Khởi tạo và khởi động Kubernetes shared informer factory (`informers.NewSharedInformerFactory`).
        
        - Cụ thể, nó thiết lập một Node Informer (`informerFactory.Core().V1().Nodes().Informer()`) với một trình xử lý sự kiện `UpdateFunc`. Trình xử lý này hiện tại ghi log các thay đổi đối với nhãn hoặc taint của node và gọi `scheduleAllUnscheduled` (một hàm đánh giá lại rộng hơn, mặc dù luồng lập lịch chính là dựa trên sự kiện cho mỗi pod). Informer này đảm bảo bộ lập lịch có một cái nhìn nhất quán cuối cùng (eventually consistent) về trạng thái của các node.
        
        - Chờ cho các bộ đệm cache của informer đồng bộ hóa (`cache.WaitForCacheSync`) trước khi tiếp tục, đảm bảo bộ lập lịch khởi động với thông tin node cập nhật.
        
        - Gọi `watchUnscheduledPods` (từ `kubernetes.go`) để bắt đầu quá trình bất đồng bộ theo dõi các pod đủ điều kiện. Hàm này trả về hai kênh: `podCh` (cho các pod cần lập lịch) và `errCh` (cho các lỗi liên quan đến watch).
        
        - Triển khai vòng lặp xử lý chính:
            - Sử dụng câu lệnh `select` để lắng nghe trên `podCh`, `errCh`, và context tắt (`ctx.Done()`).
            - Khi một pod được nhận trên `podCh`, nó gọi `schedulePod` (từ `processor.go`) để xử lý logic lập lịch cho pod cụ thể đó.
            - Ghi log bất kỳ lỗi nào nhận được trên `errCh`.
            - Quản lý việc tắt mềm mại bằng cách chờ goroutine xử lý chính hoàn thành bằng cách sử dụng `sync.WaitGroup` khi context bị hủy.
    
    + *Các lệnh gọi bên ngoài chính:* `initKubernetesClient`, `loadScoringConfig`, `watchUnscheduledPods`, `schedulePod`.

- `kubernetes.go`:
    + *Vai trò:* Đây là một tệp quan trọng đóng gói hầu hết các tương tác trực tiếp với máy chủ API Kubernetes bằng thư viện `client-go`. Nó cung cấp các lớp trừu tượng hóa trên các lệnh gọi API thô.
    
    + *Trách nhiệm chính:*
        - Hằng số `SchedulerName`: Định nghĩa tên ("custom-scheduler") mà các pod phải chỉ định trong `spec.schedulerName` để được xử lý bởi bộ lập lịch này.
    
        - `initKubernetesClient()`: Tạo và trả về một `*kubernetes.Clientset`.
        
        - `watchUnscheduledPods()`: Triển khai logic để theo dõi các pod chưa được lập lịch được gán cho `SchedulerName`, lọc theo `spec.nodeName=""`, và gửi chúng đến một kênh để xử lý. Bao gồm xử lý lỗi và logic thử lại cho watch.
        
        - `predicateChecks()`: Logic vị từ (predicate) cốt lõi. Nó nhận một pod và clientset, liệt kê các node, và lọc chúng dựa trên yêu cầu tài nguyên, bộ chọn node (node selector), taint/toleration, và trạng thái không thể lập lịch của node. Nó sử dụng các hàm trợ giúp:
            - `calculateNodeUsage()`: Tính toán các yêu cầu tài nguyên hiện tại trên các node.
            - `calculatePodResourceRequests()`: Tính toán tài nguyên được yêu cầu bởi pod mới.
            - `checkNodeResources()`: Kiểm tra xem một node có đủ tài nguyên có thể cấp phát hay không.
            - `checkNodeTaints()`: Kiểm tra toleration của pod so với taint của node.
            - `tolerationsTolerateTaint()` & `tolerationsTolerateTaints()`: Các hàm trợ giúp cho việc xử lý taint.
        
        - `bindPod()`: Xây dựng một đối tượng `v1.Binding` và sử dụng clientset để ràng buộc một pod với một node được chỉ định.
        
        - `postEvent()`: Tạo và đăng các đối tượng `v1.Event` lên API Kubernetes để báo cáo các quyết định lập lịch và lỗi.
    
    + *Các phụ thuộc chính:* `k8s.io/client-go/kubernetes`, `k8s.io/api/core/v1`, `k8s.io/apimachinery/....`

- `scoring.go`:
    + *Vai trò:* Tệp này chứa tất cả logic liên quan đến việc tính điểm các node tương thích, đây là trái tim của chiến lược ưu tiên hóa tùy chỉnh. Nó xử lý giao tiếp với Prometheus để lấy các số liệu thời gian thực.
    
    + *Các cấu trúc dữ liệu chính:*
        - `ScoringConfig`: Struct để giữ các trọng số cho điểm bộ nhớ, CPU, và affinity, được tải từ các biến môi trường.
        
        - `NodeScore`: Struct để lưu trữ điểm riêng lẻ và tổng điểm cho một node.
        
        - `MetricResponse`, `Data`, `Result`: Các struct để giải tuần tự (unmarshal) các phản hồi JSON từ API Prometheus.
    
    + *Trách nhiệm chính:*
        - Hằng số `prometheusService`: Định nghĩa địa chỉ nội bộ cụm của dịch vụ Prometheus.
        
        - Các hằng số `memPromQL`, `cpuIdlePromQL`: Định nghĩa các truy vấn PromQL để lấy số liệu bộ nhớ và CPU.
    
        - `queryPrometheus()`: Gửi các yêu cầu HTTP GET đến Prometheus, thực thi các truy vấn PromQL, và phân tích phản hồi JSON. Bao gồm xử lý lỗi cho giao tiếp với Prometheus.
        
        - `getNodeNameFromMetric()` & `parseInstanceLabel()`: Các hàm trợ giúp để trích xuất tên node Kubernetes từ các nhãn số liệu Prometheus (cụ thể là nhãn `instance`, được đặt bởi các quy tắc gán lại nhãn trong cấu hình Prometheus).
        
        - `parseMetricValue()`: Chuyển đổi các giá trị chuỗi số liệu từ Prometheus thành `float64`.
        
        - `WorkspaceNodeMetrics()`: Điều phối việc lấy cả số liệu bộ nhớ và CPU cho tất cả các node tương thích từ Prometheus.
        
        - `normalizeScore()`: Chuẩn hóa các giá trị số liệu thô (hoặc tổng affinity) về thang điểm 0-10, cần thiết cho việc tính điểm có trọng số.
        
        - `calculateAffinityScore()`: Tính toán điểm 0-10 dựa trên các quy tắc affinity node `preferredDuringSchedulingIgnoredDuringExecution` của pod và nhãn của node. Sử dụng `NodeSelectorRequirementsAsSelector` để phân tích `matchExpressions`.
        
        - `ScoreNodes()`: Hàm tính điểm chính. Nó nhận danh sách các node tương thích, pod, và `ScoringConfig`. Nó gọi `WorkspaceNodeMetrics`, sau đó đối với mỗi node, tính toán điểm bộ nhớ, CPU, và affinity, chuẩn hóa chúng, và kết hợp chúng thành tổng điểm có trọng số. Cuối cùng, nó sắp xếp các node theo tổng điểm (có phá vỡ hòa) và trả về tên của node tốt nhất.
    
    + *Các phụ thuộc chính:* Các gói HTTP, JSON, math, sort tiêu chuẩn của Go; `k8s.io/api/core/v1` (cho các kiểu pod/node); `k8s.io/apimachinery/pkg/labels`, `k8s.io/apimachinery/pkg/selection`.

- `getBestNode.go`:
    + *Vai trò:* Tệp này hoạt động như một bộ điều phối đơn giản hoặc cầu nối giữa giai đoạn vị từ và logic tính điểm chi tiết.
    
    + *Trách nhiệm chính:*
    
        - Hàm `getBestNode()` nhận danh sách các node tương thích (từ `predicateChecks`), pod cần lập lịch, và `ScoringConfig`.
        
        - Nó gọi trực tiếp `ScoreNodes()` (từ `scoring.go`) để lấy tên của node tốt nhất.
        - Sau đó, nó lặp qua danh sách `compatibleNodes` gốc để tìm và trả về đối tượng `v1.Node` đầy đủ tương ứng với `bestNodeName`.
        - Bao gồm xử lý lỗi cơ bản nếu `ScoreNodes` thất bại hoặc nếu không thể tìm thấy tên node tốt nhất trong danh sách tương thích (điều này sẽ chỉ ra một lỗi logic nội bộ).

- `processor.go`:
    + *Vai trò:* Tệp này chứa logic cấp cao nhất để xử lý một pod đơn lẻ qua toàn bộ quy trình lập lịch.
    
    + *Các cấu trúc dữ liệu chính:* `processorLock` (một `sync.Mutex` ban đầu nhằm ngăn chặn việc xử lý đồng thời cùng một pod, mặc dù ít quan trọng hơn với mô hình theo dõi dựa trên sự kiện hiện tại so với mô hình thăm dò/đối chiếu).
    
    + *Trách nhiệm chính:*
        - `schedulePod()`: Đây là hàm chính được `main.go` gọi cho mỗi pod mới.
        
            - Nó điều phối luồng lập lịch:
                1. Gọi `predicateChecks()` để lấy các node tương thích.
                2. Gọi `getBestNode()` (hàm này lại gọi `ScoreNodes()`) để chọn node tốt nhất từ danh sách tương thích.
                3. Triển khai một phương án dự phòng: nếu `getBestNode()` thất bại nhưng vẫn tồn tại các node tương thích, nó sẽ ghi log vấn đề và có thể chọn node tương thích đầu tiên làm phương án dự phòng để đảm bảo pod được lập lịch nếu có thể.
                4. Gọi `bindPod()` để gán pod cho node đã chọn.
                
        - Xử lý lỗi từ mỗi bước và đảm bảo ghi log thích hợp.
    
        - `scheduleAllUnscheduled()`: Một hàm (hiện được gọi bởi trình xử lý cập nhật của node informer trong `main.go`) liệt kê tất cả các pod chưa được lập lịch cho `custom-scheduler` và cố gắng lập lịch cho chúng. Hàm này hoạt động như một cơ chế đối chiếu, mặc dù luồng lập lịch chính là dựa trên sự kiện.

- `types.go`:
    + *Vai trò:* Tệp này chứa các định nghĩa struct Go (như `Event`, `Pod`, `Node`, `Binding`) phản chiếu các đối tượng API Kubernetes.
    
    + *Bối cảnh lịch sử:* Nó được ghi chú rõ ràng trong các bình luận là ban đầu từ dự án bộ lập lịch Kubernetes ví dụ của Kelsey Hightower.
    
    + *Trạng thái hiện tại:* Mặc dù có mặt, dự án của nhóm em hiện chủ yếu sử dụng trực tiếp các kiểu API Kubernetes chính thức, có phiên bản từ `k8s.io/api/core/v1` và các gói `k8s.io/apimachinery` khác (ví dụ: `v1.Pod`, `v1.Node`). Do đó, các kiểu tùy chỉnh trong `types.go` phần lớn là dấu tích hoặc đóng vai trò tham khảo lịch sử từ nguồn cảm hứng ban đầu của dự án. Chúng không phải là các cấu trúc dữ liệu chính được sử dụng để tương tác với API Kubernetes trong mã nguồn hiện tại.

- `Dockerfile`:
    + *Vai trò:* Định nghĩa các chỉ dẫn để xây dựng image container Docker cho bộ lập lịch tùy chỉnh.
  
    + *Các tính năng chính:*
        - Sử dụng một bản dựng đa giai đoạn (multi-stage build):
        
            - Một image `golang:1.23-alpine` (hoặc tương tự) làm giai đoạn `builder` để biên dịch ứng dụng Go. Giai đoạn này bao gồm việc sao chép `go.mod` và `go.sum` trước để lưu cache bản dựng, sau đó là phần còn lại của mã nguồn, và cuối cùng là chạy `go build`.
            
            - Lệnh dựng `CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /scheduler .` tạo ra một tệp nhị phân Linux được liên kết tĩnh, tối ưu hóa về kích thước (`-w -s` loại bỏ các ký hiệu gỡ lỗi).
            - Một image `alpine:latest` tối giản làm giai đoạn cuối cùng.
            - Chỉ sao chép tệp nhị phân đã biên dịch (`/scheduler`) từ giai đoạn `builder` vào image cuối cùng.
        - Đặt `ENTRYPOINT` thành `["/scheduler"]` để chạy ứng dụng khi container khởi động.
    + Cách tiếp cận này tạo ra một image container cuối cùng nhỏ gọn, an toàn.

=== Các tệp manifests Kubernetes

Ngoài mã Go, một số tệp YAML định nghĩa các tài nguyên Kubernetes cần thiết để triển khai và chạy bộ lập lịch cũng như các phụ thuộc của nó:

- `scheduler/custom-scheduler-deployment.yaml`:

    + Định nghĩa `Deployment` Kubernetes cho chính bộ lập lịch tùy chỉnh.
    
    + Chỉ định chạy trong không gian tên `kube-system`, số lượng bản sao (thường là 1), bộ chọn (selector), và mẫu pod (pod template).
    
    + Quan trọng là, trong đặc tả container:
        - Tham chiếu đến image Docker được xây dựng bởi `Dockerfile` (ví dụ: `gcr.io/YOUR_PROJECT_ID/custom-scheduler:v1`).
        - Đặt `imagePullPolicy: Always` (hữu ích trong quá trình phát triển).
        - Định nghĩa các biến môi trường cho `ScoringConfig` (`SCORE_WEIGHT_MEM`, `SCORE_WEIGHT_CPU`, `SCORE_WEIGHT_AFFINITY`).
        - Đưa tên của pod bộ lập lịch làm biến môi trường `POD_NAME` bằng cách sử dụng Downward API (`fieldRef: metadata.name`), được sử dụng để báo cáo sự kiện.
        - Gán `ServiceAccount` `custom-scheduler-sa`.

- `scheduler/scheduler-rbac.yaml`:

    + Định nghĩa các quyền Kiểm soát Truy cập Dựa trên Vai trò (RBAC) mà bộ lập lịch tùy chỉnh yêu cầu.
    
    + Tạo một `ServiceAccount` tên là `custom-scheduler-sa` trong không gian tên `kube-system`.
    + Định nghĩa một `ClusterRole` tên là `custom-scheduler-role` cấp các quyền cho:
        - `get, list, watch` trên `pods` và `nodes` (toàn cụm).
        - `create` trên `pods/binding` (hành động lập lịch cốt lõi).
        - `create, patch` trên `events` (để báo cáo).
    + Định nghĩa một `ClusterRoleBinding` tên là `custom-scheduler-rb` ràng buộc `custom-scheduler-role` với `ServiceAccount` `custom-scheduler-sa`.

- `scheduler/deployments/`: Thư mục con này chứa các tệp manifest YAML ví dụ để triển khai các khối lượng công việc nhằm kiểm thử bộ lập lịch:

    + `pod-preferred-affinity.yaml`: Một `Pod` minh họa affinity node `preferredDuringSchedulingIgnoredDuringExecution`, sẽ được lập lịch bởi `custom-scheduler`.
    
    + `sleep.yaml`: Một `Deployment` yêu cầu lượng bộ nhớ đáng kể, hữu ích để tạo áp lực tài nguyên.
    + `sysbench.yaml`: Một `Job` có thể chạy các bài kiểm tra hiệu năng chuyên sâu về bộ nhớ.
    + `testcustom.yaml`: Một `Deployment` Nginx đơn giản được cấu hình để sử dụng `custom-scheduler`.
    + `testdefault.yaml`: Một `Deployment` Nginx tương tự được cấu hình để sử dụng bộ lập lịch Kubernetes mặc định (bằng cách bỏ qua `schedulerName`).

- `prometheus/`: Thư mục này chứa các tệp manifest để triển khai Prometheus:
    + `clusterRole.yaml`: RBAC cho Prometheus (`ServiceAccount`, `ClusterRole`, `ClusterRoleBinding`) cho phép nó khám phá các dịch vụ, pod, node, v.v., để thu thập số liệu (scraping).
    
    + `config-map.yaml`: Chứa cấu hình Prometheus (`prometheus.yml`) và các quy tắc cảnh báo (`prometheus.rules`). Tệp `prometheus.yml` định nghĩa các công việc thu thập số liệu (scrape job), bao gồm cả những công việc cho `kubernetes-apiservers`, `kubernetes-nodes` (kubelet), `kubernetes-cadvisor`, và `kubernetes-pods` (khám phá `node-exporter` thông qua các chú thích). Các quy tắc gán lại nhãn (relabeling rule) ở đây rất cần thiết để đảm bảo các số liệu có các nhãn hữu ích như `instance` (tên node).
    
    + `prometheus-deployment.yaml`: `Deployment` cho chính máy chủ Prometheus, gắn config map và chỉ định một volume cho cơ sở dữ liệu chuỗi thời gian (TSDB) của nó, hiện tại là một `emptyDir` cho đơn giản nhưng được ghi chú để thay thế bằng `PersistentVolumeClaim` trong môi trường sản xuất. Bao gồm các probe liveness/readiness.
    
    + `prometheus-service.yaml`: Định nghĩa một `Service` `ClusterIP` để phơi bày máy chủ Prometheus trong cụm (ví dụ: trên cổng 8080, nhắm mục tiêu cổng container 9090).

- `node-exporter/node-exporter-daemonset.yml`:
    + Định nghĩa `DaemonSet` cho Prometheus Node Exporter.
    
    + Đảm bảo rằng một pod `node-exporter` chạy trên mọi node trong cụm.
    
    + Cấu hình `hostPID`, `hostIPC`, `hostNetwork` để truy cập thông tin cấp máy chủ (host).
    
    + Gắn các đường dẫn máy chủ như `/proc`, `/sys`, và `/` (rootfs) ở chế độ chỉ đọc vào container để `node-exporter` có thể thu thập số liệu từ chúng.

- `README.md`: Tệp tài liệu chính cho dự án, cung cấp tổng quan, hướng dẫn cài đặt, ví dụ sử dụng, và thông tin chi tiết về kiến trúc.


== Các khía cạnh cấu hình và triển khai

Hoạt động thành công của bộ lập lịch Kubernetes tùy chỉnh của nhóm em không chỉ dựa vào logic ứng dụng Go của nó mà còn vào một tập hợp các tài nguyên Kubernetes được cấu hình cẩn thận. Phần này trình bày chi tiết cách bộ lập lịch xác định các pod để quản lý, các quyền Kiểm soát Truy cập Dựa trên Vai trò (RBAC) mà nó yêu cầu, cấu hình triển khai của chính nó, việc thiết lập ngăn xếp giám sát cần thiết (Prometheus và Node Exporter), và cách các khối lượng công việc ví dụ được định nghĩa để kiểm thử và minh họa.

=== Nhận dạng Bộ lập lịch: Chỉ định Pod cho Lập lịch Tùy chỉnh

Một khía cạnh cơ bản của việc tích hợp một bộ lập lịch tùy chỉnh là cung cấp một cơ chế để Kubernetes và người dùng chỉ định pod nào sẽ được xử lý bởi nó, thay vì bởi bộ lập lịch Kubernetes mặc định hoặc các bộ lập lịch tùy chỉnh khác có thể có trong cụm.

*Cơ chế:* Bộ lập lịch tùy chỉnh của nhóm em sử dụng cơ chế Kubernetes tiêu chuẩn cho mục đích này: trường `spec.schedulerName` trong đặc tả của Pod.

  - *Cấu hình tệp manifest Pod (Pod Manifest):* Để hướng một pod đến bộ lập lịch tùy chỉnh của nhóm em, tệp manifest YAML của nó phải bao gồm:
    ```yaml
    apiVersion: v1
    kind: Pod # hoặc một phần của mẫu Deployment, StatefulSet, Job, v.v.
    metadata:
      name: my-custom-scheduled-pod
    spec:
      schedulerName: custom-scheduler # Chuỗi chính xác này là quan trọng
      containers:
      - name: my-container
        image: nginx
    ```
    
  - *Tham chiếu Hằng số:* Chuỗi "`custom-scheduler`" được định nghĩa là hằng số `SchedulerName` trong `scheduler/kubernetes.go`. Cơ chế theo dõi của bộ lập lịch (trong `watchUnscheduledPods`) lọc một cách tường minh các pod có `schedulerName` này và đang ở trạng thái chờ (pending).
  
  - *Hành vi Mặc định:* Nếu `spec.schedulerName` bị bỏ qua trong đặc tả của pod, hoặc nếu nó được đặt thành `default-scheduler`, pod sẽ được xử lý bởi bộ lập lịch mặc định tích hợp sẵn của Kubernetes. Triển khai ví dụ `scheduler/deployments/testdefault.yaml` của nhóm em minh họa điều này bằng cách bỏ qua trường `schedulerName`.

Việc chỉ định tường minh này đảm bảo một hợp đồng rõ ràng: chỉ những pod tường minh chọn tham gia mới được quản lý bởi logic tùy chỉnh của nhóm em, cho phép cùng tồn tại với bộ lập lịch mặc định.

=== Kiểm soát truy cập dựa trên Vai trò (RBAC)

Cả bộ lập lịch tùy chỉnh của nhóm em và Prometheus đều yêu cầu các quyền cụ thể để tương tác với máy chủ API Kubernetes và thực hiện các chức năng của chúng. Các quyền này được cấp bằng cách sử dụng các tài nguyên RBAC của Kubernetes: `ServiceAccount`, `ClusterRole`, và `ClusterRoleBinding`.

==== *RBAC cho bộ lập lịch tùy chỉnh (`scheduler/scheduler-rbac.yaml`):*
Pod bộ lập lịch tùy chỉnh của nhóm em cần các quyền để quan sát trạng thái của cụm và thực thi các quyết định lập lịch của nó.

  - *`ServiceAccount` (`custom-scheduler-sa`):*
    + Một `ServiceAccount` chuyên dụng có tên `custom-scheduler-sa` được tạo trong không gian tên `kube-system`. Pod bộ lập lịch tùy chỉnh chạy dưới danh tính này. Việc triển khai các thành phần của bộ lập lịch vào `kube-system` là một thực tiễn phổ biến đối với các tiện ích bổ sung cấp cụm.

  - *`ClusterRole` (`custom-scheduler-role`):*
    + `ClusterRole` này định nghĩa các quyền cần thiết ở phạm vi cụm:
        - `apiGroups: [""]`, `resources: ["pods"]`, `verbs: ["get", "list", "watch"]`: Để tìm và giám sát các pod chưa được lập lịch trên tất cả các không gian tên.
        
        - `apiGroups: [""]`, `resources: ["nodes"]`, `verbs: ["get", "list", "watch"]`: Để lấy thông tin node cho các kiểm tra vị từ và tính điểm (ví dụ: nhãn, taint, tài nguyên có thể cấp phát).
        
        - `apiGroups: [""]`, `resources: ["pods/binding"]`, `verbs: ["create"]`: Đây là quyền cốt lõi cho phép bộ lập lịch gán một pod cho một node bằng cách tạo một đối tượng `Binding`. Ràng buộc được tạo trong không gian tên của pod.
        
        - `apiGroups: [""]`, `resources: ["events"]`, `verbs: ["create", "patch"]`: Để tạo các đối tượng `Event` của Kubernetes nhằm báo cáo các thành công hoặc thất bại trong lập lịch.
    
    + Các quyền cho `pods/status` (patch, update) được chú thích lại (comment out) vì bộ lập lịch của nhóm em sử dụng tài nguyên con `pods/binding`, đây là phương pháp được ưu tiên.
  
  - *`ClusterRoleBinding` (`custom-scheduler-rb`):*
    + `ClusterRoleBinding` này liên kết `custom-scheduler-role` (`ClusterRole`) với `ServiceAccount` `custom-scheduler-sa` (trong không gian tên `kube-system`). Việc cấp quyền này áp dụng trên toàn cụm, cho phép bộ lập lịch hoạt động trên các pod và node từ bất kỳ không gian tên nào theo yêu cầu chức năng của nó.

==== *RBAC cho Prometheus (`prometheus/clusterRole.yaml`):*
Prometheus cũng yêu cầu các quyền để khám phá và thu thập số liệu từ các thành phần Kubernetes khác nhau.
  - *`ServiceAccount` (`prometheus-sa`):*
    + Một `ServiceAccount` chuyên dụng có tên `prometheus-sa` được tạo trong không gian tên `monitoring` (nơi Prometheus được triển khai).
  
  - *`ClusterRole` (`prometheus`):*
    + Cấp các quyền cho:
        - `apiGroups: [""]`, `resources: ["nodes", "services", "endpoints", "pods"]`, `verbs: ["get", "list", "watch"]`: Cần thiết cho việc khám phá dịch vụ Kubernetes (`kubernetes_sd_configs`), cho phép Prometheus tìm các mục tiêu để thu thập số liệu (ví dụ: các pod có chú thích cụ thể, các điểm cuối dịch vụ, các node cho số liệu kubelet/cadvisor).
        
        - `apiGroups: [""]`, `resources: ["nodes/proxy"]`, `verbs: ["get", "list", "watch"]`: Cho phép Prometheus truy cập trực tiếp các điểm cuối API của Kubelet thông qua proxy của máy chủ API, được sử dụng bởi các công việc thu thập số liệu như `kubernetes-nodes` và `kubernetes-cadvisor`.
        
        - `apiGroups: ["networking.k8s.io"]`, `resources: ["ingresses"]`, `verbs: ["get", "list", "watch"]`: Để khám phá và thu thập số liệu từ các đối tượng Ingress nếu được cấu hình.
        
        - `nonResourceURLs: ["/metrics"]`, `verbs: ["get"]`: Để thu thập số liệu từ điểm cuối `/metrics` của chính máy chủ API Kubernetes.
        
  - *`ClusterRoleBinding` (`prometheus`):*
    + Liên kết `ClusterRole` `prometheus` với `ServiceAccount` `prometheus-sa` (trong không gian tên `monitoring`).

Các cấu hình RBAC này tuân thủ nguyên tắc đặc quyền tối thiểu (principle of least privilege) ở những nơi khả thi, chỉ cấp các quyền cần thiết để mỗi thành phần hoạt động chính xác.

=== Triển khai bộ lập lịch tùy chỉnh

Chính bộ lập lịch tùy chỉnh được triển khai dưới dạng một `Deployment` Kubernetes. tệp manifest này (`scheduler/custom-scheduler-deployment.yaml`) chỉ định cách pod của bộ lập lịch sẽ được cấu hình và chạy.

  - *Không gian tên (Namespace):* Được triển khai vào không gian tên `kube-system`, phổ biến cho các dịch vụ cốt lõi của cụm.
  
  - *Số bản sao (Replicas):* Thường được đặt là `1`. Việc chạy nhiều bản sao của một bộ lập lịch tùy chỉnh mà tất cả cùng theo dõi các pod giống nhau có thể dẫn đến tình trạng tranh chấp (race condition) khi nhiều instance cố gắng lập lịch cho cùng một pod. Cơ chế bầu chọn lãnh đạo (leader election) sẽ cần thiết cho một thiết lập có tính sẵn sàng cao, điều này nằm ngoài phạm vi hiện tại của dự án của nhóm em nhưng là một mẫu tiêu chuẩn cho các bộ lập lịch trong môi trường sản xuất.
  
  - *`serviceAccountName: custom-scheduler-sa`*: Đảm bảo pod của bộ lập lịch chạy với các quyền được cấp bởi cấu hình RBAC đã thảo luận ở trên.
  
  - *Image Container:*
    + `image: gcr.io/YOUR_PROJECT_ID/custom-scheduler:v1` (hoặc đường dẫn thích hợp đến registry container của bạn). Điều này tham chiếu đến image Docker được xây dựng bởi `Dockerfile`.
    
    + `imagePullPolicy: Always` được chỉ định, hữu ích trong quá trình phát triển để đảm bảo image mới nhất được kéo về nếu tag được sử dụng lại. Đối với các bản phát hành ổn định, `IfNotPresent` có thể được ưu tiên hơn.
  
  - *Biến môi trường cho cấu hình tính điểm:* Đây là một khía cạnh quan trọng để tinh chỉnh hành vi của bộ lập lịch mà không cần xây dựng lại image:
    + `SCORE_WEIGHT_MEM`: Định nghĩa trọng số cho điểm bộ nhớ khả dụng (ví dụ: `"0.6"`).
  
    + `SCORE_WEIGHT_CPU`: Định nghĩa trọng số cho điểm CPU khả dụng (lõi rảnh) (ví dụ: `"0.4"`).
    
    + `SCORE_WEIGHT_AFFINITY`: Định nghĩa trọng số (hệ số nhân) cho điểm node affinity (ví dụ: `"1.0"`).
    
    + Các giá trị này được đọc bởi `loadScoringConfig` trong `scheduler/main.go`.
  
  - *Downward API cho `POD_NAME`:*
    + Một biến môi trường `POD_NAME` được đưa vào container:
      ```yaml
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      ```
      
    + Điều này cho phép bộ lập lịch biết tên pod của chính nó, sau đó được sử dụng trong trường `ReportingInstance` của các đối tượng `Event` Kubernetes mà nó tạo ra, hỗ trợ việc xác định nguồn gốc của các sự kiện từ bộ lập lịch.

Cấu hình triển khai này đảm bảo rằng bộ lập lịch tùy chỉnh của nhóm em chạy với danh tính, quyền và các tham số hành vi (trọng số tính điểm) chính xác.

=== Triển khai công cụ giám sát thông số (Prometheus & Node Exporter)

Để bộ lập lịch tùy chỉnh của nhóm em hoạt động (vì nó dựa vào các số liệu thời gian thực), một ngăn xếp giám sát Prometheus phải được triển khai và cấu hình chính xác trong cụm.

==== *Node Exporter (`node-exporter/node-exporter-daemonset.yml`):*
Node Exporter chịu trách nhiệm thu thập các số liệu chi tiết ở cấp máy chủ (host).

  - *Triển khai dưới dạng `DaemonSet`:* Điều này đảm bảo rằng một instance của pod Node Exporter chạy trên mọi node có thể lập lịch trong cụm.

  - *Truy cập đặc quyền:* Đặc tả pod bao gồm:
    + `hostPID: true`, `hostIPC: true`, `hostNetwork: true`: Những cài đặt này cung cấp cho container Node Exporter quyền truy cập vào các không gian tên của máy chủ, điều này cần thiết để thu thập một số số liệu nhất định.
    + `securityContext: privileged: true`: Mặc dù phạm vi rộng, điều này phổ biến đối với Node Exporter để truy cập tất cả thông tin hệ thống cần thiết.
  
  - *Gắn Kết đường dẫn máy chủ (Host Path Mounts):* Các thư mục máy chủ quan trọng được gắn kết ở chế độ chỉ đọc vào container:
    + `/proc` được gắn tại `/host/proc`
    + `/sys` được gắn tại `/host/sys`
    + `/` (hệ thống tệp gốc) được gắn tại `/rootfs`
    + Các điểm gắn kết này cho phép Node Exporter đọc các tệp từ hệ thống tệp `/proc` và `/sys` của máy chủ, là nguồn cung cấp nhiều số liệu.
  
  - *Đối số (Arguments):* Các đối số cụ thể được truyền cho Node Exporter để cấu hình các bộ thu thập (collector) và đường dẫn của nó, ví dụ: `--path.procfs=/host/proc`, `--path.sysfs=/host/sys`, và các loại trừ cho một số loại hệ thống tệp và điểm gắn kết nhất định để tránh sự cố hoặc dữ liệu dư thừa.
  
  - *Chú thích khám phá Prometheus (Prometheus Discovery Annotations):*
    + `prometheus.io/scrape: "true"`
    + `prometheus.io/port: "9100"`
    + Các chú thích này báo hiệu cho Prometheus (khi được cấu hình với `kubernetes_sd_configs` thích hợp) rằng pod này sẽ được thu thập số liệu trên cổng 9100.

==== *Prometheus (thư mục `prometheus/`):*
Máy chủ Prometheus tổng hợp và cung cấp các số liệu này.
  - *Cấu hình (`prometheus/config-map.yaml`):*
    + `ConfigMap` này (tên là `prometheus-server-conf`, được triển khai trong không gian tên `monitoring`) chứa tệp cấu hình Prometheus chính (`prometheus.yml`) và các quy tắc cảnh báo ví dụ (`prometheus.rules`).
    
    + *Điểm nổi bật của `prometheus.yml`:*
        - `scrape_interval` và `evaluation_interval` được định nghĩa toàn cục.
        - `scrape_configs`: Phần này rất quan trọng. Nó định nghĩa các công việc (job) khác nhau về cách Prometheus khám phá và thu thập số liệu từ các mục tiêu:
        
            - `kubernetes-apiservers`: Thu thập số liệu từ điểm cuối `/metrics` của máy chủ API Kubernetes.
            
            - `kubernetes-nodes`: Thu thập số liệu từ Kubelet (`/metrics`).
            
            - `kubernetes-cadvisor`: Thu thập số liệu cAdvisor từ Kubelet (`/metrics/cadvisor`), cung cấp thông tin sử dụng tài nguyên ở cấp container.
            
            - `kubernetes-pods`: Công việc này sử dụng khám phá dịch vụ `role: pod`. Nó được cấu hình với `relabel_configs` để:
                
                - Chỉ giữ lại các pod có chú thích `prometheus.io/scrape: "true"`.
                
                - Sử dụng các chú thích `prometheus.io/path` và `prometheus.io/port` để tùy chỉnh việc thu thập số liệu.
                
                - Quan trọng là, đối với `node-exporter`, nó đảm bảo nhãn `instance` trên các số liệu được thu thập được đặt thành tên node Kubernetes (lấy từ `__meta_kubernetes_pod_node_name`), điều mà bộ lập lịch của nhóm em dựa vào để tương quan số liệu với các node.
            
            - `kubernetes-service-endpoints`: Khám phá và thu thập số liệu từ các dịch vụ được chú thích cho Prometheus.
            
  - *Triển khai Prometheus (`prometheus/prometheus-deployment.yaml`):*
  
    + Triển khai chính máy chủ Prometheus (sử dụng `prom/prometheus:v2.49.1` hoặc một phiên bản gần đây tương tự) trong không gian tên `monitoring`.
    
    + Gắn `ConfigMap` `prometheus-server-conf` vào `/etc/prometheus/`.
    
    + Cấu hình các đối số dòng lệnh cho Prometheus, ví dụ: `--config.file`, `--storage.tsdb.path`.
    
    + Sử dụng một volume `emptyDir` cho `--storage.tsdb.path` để đơn giản hóa trong dự án này. *Tệp README ghi chú chính xác rằng đối với môi trường sản xuất, nên sử dụng `PersistentVolumeClaim` (PVC) để duy trì dữ liệu Prometheus qua các lần khởi động lại pod.*
    
    + Bao gồm các probe liveness (`/-/healthy`) và readiness (`/-/ready`) để hoạt động mạnh mẽ.
    
    + Gán `ServiceAccount` `prometheus-sa`.
  
  - *Dịch vụ Prometheus (`prometheus/prometheus-service.yaml`):*
    + Phơi bày (expose) việc triển khai Prometheus thông qua một `Service` `ClusterIP` có tên `prometheus-service` trong không gian tên `monitoring`.
    
    + Lắng nghe trên cổng `8080` trong cụm và nhắm mục tiêu cổng `9090` trên các pod Prometheus (nơi giao diện người dùng web và API của Prometheus được phơi bày). Bộ lập lịch tùy chỉnh của nhóm em sử dụng địa chỉ dịch vụ này (`http://prometheus-service.monitoring.svc.cluster.local:8080`) để truy vấn số liệu.

Việc triển khai và cấu hình cẩn thận ngăn xếp giám sát này là điều kiện tiên quyết cho bộ lập lịch tùy chỉnh của nhóm em, vì các quyết định của nó được điều khiển bởi dữ liệu từ các số liệu mà Prometheus cung cấp.

=== Kiểm thử và minh họa (`scheduler/deployments/`)

Để xác thực chức năng của bộ lập lịch tùy chỉnh của nhóm em và minh họa hành vi của nó so với bộ lập lịch mặc định, một số tệp manifest ví dụ được cung cấp trong thư mục `scheduler/deployments/`.

  - *`sleep.yaml` (`Deployment`):* Triển khai các pod chủ yếu tiêu thụ bộ nhớ (yêu cầu `1600Mi`). Điều này giúp tạo ra một kịch bản trong đó tính khả dụng của bộ nhớ khác nhau giữa các node, cho phép quan sát vị trí đặt pod dựa trên nhận biết bộ nhớ của bộ lập lịch.
  
  - *`sysbench.yaml` (`Job`):* Định nghĩa một `Job` để chạy `sysbench` nhằm kiểm thử bộ nhớ. Nó bao gồm `podAntiAffinity` để cố gắng lập lịch các pod của nó trên các node khác với các pod của triển khai `sleep`, ảnh hưởng hơn nữa đến việc phân phối tài nguyên để kiểm thử.
  
  - *`testdefault.yaml` (`Deployment`):* Triển khai một ứng dụng Nginx đơn giản *mà không* chỉ định `schedulerName`. Pod này sẽ được lập lịch bởi bộ lập lịch mặc định của Kubernetes, đóng vai trò là cơ sở để so sánh.
  
  - *`testcustom.yaml` (`Deployment`):* Triển khai một ứng dụng Nginx tương tự nhưng đặt tường minh `spec.schedulerName: custom-scheduler`. Pod này sẽ được xử lý bởi logic lập lịch tùy chỉnh của nhóm em. So sánh vị trí đặt của nó với pod `testdefault` trong các điều kiện tải cụm khác nhau sẽ minh họa tác động của bộ lập lịch tùy chỉnh.
  
  - *`pod-preferred-affinity.yaml` (`Pod`):* Một tệp manifest Pod độc lập được thiết kế để kiểm thử tính năng tính điểm node affinity. Nó bao gồm các quy tắc `spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution` với các trọng số khác nhau cho các node được gắn nhãn `zone=a` so với `zone=b`. Nó cũng chỉ định `schedulerName: custom-scheduler`. Điều này cho phép quan sát trực tiếp cách các ưu tiên affinity ảnh hưởng đến việc tính điểm và quyết định vị trí đặt cuối cùng khi các nhãn node được đặt một cách thích hợp.
  - *`pod-node-selector-1.yaml` (`Deployment`):* Tệp manifest này định nghĩa một `Deployment` cũng sử dụng `custom-scheduler`. Mục đích chính của nó là để kiểm thử khả năng lựa chọn node. Nó bao gồm một trường `spec.template.spec.nodeSelector`, yêu cầu các pod chỉ được lập lịch trên các node được gắn nhãn `group: red`. Điều này cho phép xác minh cách bộ lập lịch tùy chỉnh xử lý các ràng buộc lựa chọn node rõ ràng.
  - *`pod-toleration-1.yaml` (`Deployment`):* Tệp manifest này được thiết kế để kiểm thử cách bộ lập lịch tùy chỉnh xử lý các taint và toleration. Nó chỉ định `schedulerName: custom-scheduler` và bao gồm một mục `spec.template.spec.tolerations`. Toleration cụ thể này cho phép các pod của deployment này được lập lịch trên các node có một taint cụ thể (`key1=value1:NoSchedule`). Điều này rất quan trọng để quan sát xem bộ lập lịch tùy chỉnh có xác định và sử dụng chính xác các node mà nếu không sẽ bị hạn chế bởi các taint hay không, miễn là pod có toleration cần thiết.
== Demo
Video demo hoàn chỉnh được đăng tải tại #link("https://github.com/HynDuf/custom-kubernetes-scheduler/blob/master/demo_final.mp4")[Youtube - Custom Kubernetes Scheduler Demo]. Những lệnh dùng để chạy demo được đăng tải tại #link("https://github.com/HynDuf/custom-kubernetes-scheduler/blob/master/DEMO.md")[Github - DEMO.md].
=== Set up Google Kubernetes Engine (GKE)

Thực hiện cài đặt GKE theo các bước bên dưới

#figure(
  image("../images/demo/google-cloud.png"),
  caption: [Màn hình Google Cloud]
)

#figure(
  image("../images/demo/project.png"),
  caption: [Lựa chọn dự án]
)
#figure(
  image("../images/demo/cluster.png"),
  caption: [Truy cập vào dịch vụ cluster của GKE]
)

#figure(
  image("../images/demo/kubernetes-api.png"),
  caption: [Bật API Kubernetes]
)

#figure(
  image("../images/demo/create-cluster.png"),
  caption: [Tạo cluster mới]
)

#figure(
  image("../images/demo/setup-cluster.png"),
  caption: [Thiết lập Cluster]
)

#figure(
  image("../images/demo/connect-1.png"),
  caption: [Thiết lập kết nối đến master]
)

#figure(
  image("../images/demo/connect-2.png"),
  caption: [Lấy mã kết nối]
)

#figure(
  image("../images/demo/cloud-shell.png"),
  caption: [Truy cập bằng Google Cloud Shell]
)

Thực hiện các bước sau trên Google Cloud Shell để clone dự án trình lập lịch tùy chỉnh và build và push image Docker tương ứng của trình lập lịch lên registry của Google Cloud.

```sh
# Clone the custom scheduler repository (or your fork)
git clone https://github.com/HynDuf/custom-kubernetes-scheduler.git
cd custom-kubernetes-scheduler

# --- Build and Push Custom Scheduler Docker Image ---
cd scheduler
# The following commands build and push the scheduler image to Google Container Registry (GCR).
# Ensure PROJECT_ID is correctly captured from your gcloud config.
PROJECT_ID=$(gcloud config get-value project)
docker build -t "gcr.io/${PROJECT_ID}/custom-scheduler:v1" .
gcloud auth configure-docker gcr.io --quiet # Authenticate Docker with GCR
docker push "gcr.io/${PROJECT_ID}/custom-scheduler:v1"
cd ..
```

Sau đó chỉnh lại đường dẫn của image custom scheduler trong tệp manifest `scheduler/custom-scheduler-deployment.yaml` tương ứng với đường dẫn image ở bên trên.

Tiếp đến, tạo namespace `monitoring` và chạy cái Pods liên quan tới Prometheus và Node Exporter để truy xuất dữ liệu của các nodes:

```sh
# --- Deploy Monitoring Components (Prometheus & Node Exporter) ---
# Create a dedicated namespace for monitoring components
kubectl create namespace monitoring

# Deploy Node Exporter (collects hardware and OS metrics from each node)
kubectl apply -f node-exporter/node-exporter-daemonset.yml

# Deploy Prometheus (monitoring system and time series database)
# This includes RBAC, ConfigMap, Deployment, and Service for Prometheus
kubectl apply -f prometheus/clusterRole.yaml
kubectl apply -f prometheus/config-map.yaml -n monitoring
kubectl apply -f prometheus/prometheus-deployment.yaml -n monitoring
kubectl apply -f prometheus/prometheus-service.yaml -n monitoring

# Verify monitoring components are running
kubectl get pods -o wide -n monitoring
# You should see one `node-exporter-*` p
```

#figure(
  image("../images/demo/demo-1.png"),
  caption: [Sau khi chạy cái Pods liên quan tới Prometheus và Node Exporter]
)

Truy cập vào Web UI của Prometheus ta sẽ thấy giao diện và thử truy vấn bộ nhớ còn lại của 3 máy.

#figure(
  image("../images/demo/demo-2.png"),
  caption: [Web UI của Prometheus]
)

Sau đó, ta sẽ deploy trình lập lịch tùy chỉnh như sau:

```sh 
# --- Deploy the Custom Scheduler ---
# Apply RBAC rules for the custom scheduler
kubectl apply -f scheduler/scheduler-rbac.yaml
# Deploy the custom scheduler itself (ensure you've updated the image name in this YAML)
kubectl apply -f scheduler/custom-scheduler-deployment.yaml

# --- Watch Custom Scheduler Logs ---
kubectl logs -n kube-system -l app=custom-scheduler -f --tail=100
```

#figure(
  image("../images/demo/demo-3.png"),
  caption: [Xem logs của trình lập lịch tùy chỉnh sau khi vừa deploy]
)

=== Default Scheduler vs Custom Scheduler

Sau khi cài đặt thành công thì ta sẽ test 2 trình lập lịch như sau. Ta có `sleep.yaml` sẽ tạo ra 2 Pods yêu cầu 1600Mi bộ nhớ nhưng thật ra không hề sử dụng bộ nhớ, còn `sysbench.yaml` sẽ yêu cầu 0Mi nhưng thực chất lại sử dụng lên đến 2Gib bộ nhớ của node.

```sh 
# --- Demo: Resource-Aware Scheduling ---
# This demo highlights how the custom scheduler considers actual resource usage,
# unlike the default scheduler which primarily looks at resource requests.

# Deploy 'sleep.yaml': Requests 1600Mi Memory, but actually uses very little.
# Deploy 'sysbench.yaml': Requests 0Mi Memory, but actually consumes nearly 2GiB of Memory.
kubectl apply -f scheduler/deployments/sleep.yaml
kubectl apply -f scheduler/deployments/sysbench.yaml

# Wait for these pods to be scheduled and running.
# Check their status and on which nodes they are placed:
kubectl get pods -o wide
```

#figure(
  image("../images/demo/demo-4.png"),
  caption: [2 nodes chạy 2 pods `sleep.yaml` và 1 node còn lại chạy pod `sysbench.yaml`]
)

#figure(
  image("../images/demo/demo-5.png"),
  caption: [Node chạy `sysbench.yaml` có lượng memory requested thấp]
)

#figure(
  image("../images/demo/demo-6.png"),
  caption: [Node chạy `sleep.yaml` có lượng memory requested cao]
)

Tuy vậy, nodes chạy `sleep.yaml` lại có memory trống cao hơn nhiều so với node chạy `sysbench.yaml`.

#figure(
  image("../images/demo/demo-7.png"),
  caption: [Thực tế lượng memory trống của các node]
)

Sau đó, ta thử deploy `testdefault.yaml` (sử dụng default scheduler) và `testcustom.yaml` (sử dụng scheduler custom của nhóm).

#figure(
  image("../images/demo/demo-8.png"),
  caption: [`testdefault.yaml` được chạy trên máy chạy `sysbench.yaml` (mặc dù máy này đang có rất ít memory trống), còn `testcustom.yaml` được chạy trên máy chạy `sleep.yaml` (máy đang có gần như toàn bộ memory trống)]
)

Xem logs của custom scheduler ta sẽ thấy 3 máy được đánh điểm só như thế nào. Để ý rằng máy chạy `sysbench.yaml` có điểm memory và CPU rất thấp nên scheduler đã chọn máy chạy `sleep.yaml` có điểm số cao hơn nhiều.

#figure(
  image("../images/demo/demo-9.png"),
  caption: [Logs của custom scheduler]
)
=== Node Selector

Ngoài ra, custom scheduler của nhóm còn có tính năng lập lịch dựa trên node có label cụ thể.

```sh 
# --- Demo: Node Selector ---
# Label a node (replace [CHOSEN_NODE_FOR_LABEL] with an actual node name from `kubectl get nodes`):
kubectl label node [CHOSEN_NODE_FOR_LABEL] group=red --overwrite

# Deploy a pod that uses a nodeSelector to target the labeled node:
kubectl apply -f scheduler/deployments/pod-node-selector-1.yaml
# Check pod placement and custom scheduler logs:
kubectl get pods -o wide
kubectl logs -n kube-system -l app=custom-scheduler -f --tail=100
```

Khi xem logs, ta sẽ thấy chỉ tìm được 1 node thỏa mãn label `group=red`.

#figure(
  image("../images/demo/demo-10.png"),
  caption: [Logs của custom scheduler]
)

=== Taint and Tolerants
Custom scheduler của nhóm cũng có tính năng lập lịch dựa taints và tolerations.

```sh 
# --- Demo: Taints and Tolerations ---
# Taint two different nodes (replace placeholders with actual node names from `kubectl get nodes`):
kubectl taint nodes [CHOSEN_NODE_1_FOR_TAINT] key1=value1:NoSchedule --overwrite
kubectl taint nodes [CHOSEN_NODE_2_FOR_TAINT] key2=value2:NoSchedule --overwrite

# Deploy 'pod-toleration-1.yaml'. This pod only tolerates 'key1=value1:NoSchedule'.
# It should be scheduled on [CHOSEN_NODE_1_FOR_TAINT] or the remaining node.
# [CHOSEN_NODE_2_FOR_TAINT] will not pass the predicate check because the pod doesn't tolerate its taint.
kubectl apply -f scheduler/deployments/pod-toleration-1.yaml
```

Khi xem logs, ta sẽ thấy chỉ tìm được 2 node thỏa mãn, là node có taint `key1=value1` và node không có taint nào.

#figure(
  image("../images/demo/demo-11.png"),
  caption: [Logs của custom scheduler]
)
=== Node Affinity

Ngoài ra, điểm số của mỗi node cũng được ưu tiên dựa trên node affinity. Ở đây ta sẽ đánh dấu 2 node, một node `zone=a` (được ưu tiên `weight=80` và node `zone=b` được ưu tiên `weight=20`).

```sh 
# --- Demo: Node Affinity ---
# Label two different nodes (replace placeholders with actual node names from `kubectl get nodes`):
kubectl label node [CHOSEN_NODE_1_FOR_AFFINITY_LABEL] zone=a
kubectl label node [CHOSEN_NODE_2_FOR_AFFINITY_LABEL] zone=b

# Deploy 'pod-preferred-affinity.yaml'. This pod has a preferredNodeSchedulingIgnoredDuringExecution
# affinity for nodes with label 'zone=a' (weight: 80) or 'zone=b' (weight: 20).
kubectl apply -f scheduler/deployments/pod-preferred-affinity.yaml
```

Ta sẽ thấy node có `zone=a` được tăng thêm điểm Affinity là 8 và node có `zone=b` được tăng thêm điểm Affinity là 2.

#figure(
  image("../images/demo/demo-12.png"),
  caption: [Logs của custom scheduler]
)

