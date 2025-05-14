#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Bộ lập lịch Kubernetes <chuong2>
]


#heading(level: 2, "Giới thiệu chung")

Trong hệ sinh thái điện toán đám mây hiện đại, Kubernetes đã nổi lên như một nền tảng quản lý container không thể thiếu cho các doanh nghiệp từ nhỏ đến lớn. Tại trung tâm của hệ thống phức tạp này, bộ lập lịch (Scheduler) đóng vai trò quan trọng như một bộ não điều phối, quyết định cách phân bổ tài nguyên tính toán một cách tối ưu nhất.

Bộ lập lịch không chỉ đơn thuần là một cơ chế phân bổ tài nguyên mà còn là một hệ thống ra quyết định phức tạp, cân nhắc hàng chục yếu tố khác nhau để đảm bảo rằng mỗi Pod được đặt vào Node phù hợp nhất. Điều này tương tự như một người quản lý nhà hàng giỏi biết cách sắp xếp khách hàng vào những bàn phù hợp dựa trên kích thước nhóm, yêu cầu đặc biệt, và trạng thái của nhà hàng tại thời điểm đó.

Sự phức tạp của bộ lập lịch xuất phát từ việc nó phải cân bằng giữa nhiều mục tiêu đôi khi xung đột nhau: tối đa hóa việc sử dụng tài nguyên để tiết kiệm chi phí, đảm bảo hiệu suất ứng dụng, duy trì tính sẵn sàng cao, và tuân thủ các ràng buộc về bảo mật, phần cứng cũng như chính sách kinh doanh.

Bộ lập lịch mặc định của Kubernetes có tên là kube-scheduler, tuy nhiên người dùng cũng có thể tùy chỉnh hoặc xây dựng các bộ lập lịch riêng phục vụ những nhu cầu đặc thù. Trong chương này, chúng ta sẽ đi sâu vào cơ chế hoạt động, các bước chính trong quy trình lập lịch, các yếu tố ảnh hưởng đến quyết định lập lịch và khả năng mở rộng thông qua cấu hình hoặc viết bộ lập lịch tùy chỉnh.

#heading(level: 2, "Khái niệm lập lịch trong Kubernetes")
Lập lịch (scheduling) trong Kubernetes là quá trình xác định và gán một Pod chưa được gán Node đến một Node phù hợp nhất trong cluster để đảm bảo Pod có thể chạy. Mỗi khi có một Pod mới được tạo ra (thường thông qua Deployment, StatefulSet hoặc trực tiếp qua API), hệ thống sẽ đặt nó ở trạng thái “chưa được lập lịch” (Pending) cho đến khi bộ lập lịch chọn một Node để chạy nó.

Trong một cụm Kubernetes, các Node thường có năng lực phần cứng khác nhau (CPU, RAM, ổ đĩa, GPU…) và đồng thời cũng có thể có các nhãn, taint, hoặc chính sách đặc thù. Chính vì vậy, không phải Pod nào cũng có thể chạy trên bất kỳ Node nào. Bộ lập lịch cần phải đảm bảo rằng Pod được chạy trên Node có đủ tài nguyên và đáp ứng các yêu cầu mà Pod đưa ra.

#heading(level: 2, "Trình lập lịch mặc định kube-scheduler")

kube-scheduler là bộ lập lịch mặc định trong hệ thống Kubernetes, hoạt động như một thành phần độc lập thuộc Control Plane. Vai trò chính của nó là quyết định Node nào trong cụm (cluster) sẽ được gán để chạy một Pod mới.

Bất cứ khi nào một Pod được tạo ra mà chưa được gán Node (.spec.nodeName chưa có giá trị), kube-scheduler sẽ tự động phát hiện và bắt đầu quá trình lập lịch cho Pod đó.

#heading(level: 3, "Kiến trúc")

Về mặt kiến trúc, kube-scheduler được tổ chức thành các thành phần chính sau:

#heading(level: 4, "Chính sách (Policy)")
Hiện tại, cấu hình khởi chạy của chính sách lập lịch được sử dụng bởi kube-scheduler hỗ trợ ba định dạng: tệp cấu hình (configuration file), tham số dòng lệnh (command-line parameter), và ConfigMap. Chính sách lập lịch có thể được cấu hình để chỉ định các bộ lọc (predicates), các ưu tiên (priorities), các bộ mở rộng (extenders), và các plugin của Scheduler Framework mới nhất được sử dụng trong quá trình lập lịch chính.

#heading(level: 4, "Trình thông báo (Informer)")
Khi khởi động, Kubernetes scheduler lấy dữ liệu cần thiết để lập lịch từ API server của Kubernetes thông qua một informer bằng cách sử dụng các API List và Watch. Dữ liệu này bao gồm các Pod, Node, Persistent Volumes (PV), và Persistent Volume Claim (PVC). Những dữ liệu này được tiền xử lý và lưu trữ dưới dạng dữ liệu được bộ nhớ đệm của Kubernetes scheduler.

#heading(level: 4, "Chuỗi quy trình lập lịch (Schedule Pipeline)")
Kubernetes scheduler chèn các Pod cần được lập lịch vào một hàng đợi (queue) thông qua một informer. Các Pod này sẽ được lấy ra tuần tự từ hàng đợi và đưa vào chuỗi quy trình lập lịch.

Chuỗi quy trình lập lịch được chia thành ba luồng chính: luồng lập lịch (schedule thread), luồng chờ (wait thread), và luồng ràng buộc (bind thread).

#heading(level: 5, "Luồng lập lịch (Schedule Thread)")

Luồng lập lịch được chia thành các giai đoạn sau:

- Tiền lọc (Pre-Filter): Chuẩn bị và kiểm tra dữ liệu trước khi lọc.

- Lọc (Filter): Lựa chọn các Node phù hợp với yêu cầu của Pod.

- Hậu lọc (Post-Filter): Xử lý sau khi lọc, thường kiểm tra các Node được chọn.

- Chấm điểm (Score): Chấm điểm và sắp xếp các Node đã chọn.

- Đặt trước (Reserve): Đặt Pod vào bộ nhớ đệm của Node được sắp xếp tối ưu, cho thấy Pod đã được gán vào Node đó. Điều này giúp các Pod tiếp theo trong hàng đợi lập lịch biết được Pod đã được gán vào Node nào khi thực hiện các bước lọc và chấm điểm.

#heading(level: 5, "Luồng chờ (Wait Thread)")

Luồng chờ đảm nhận việc chờ đợi các tài nguyên liên quan đến Pod sẵn sàng, chẳng hạn như chờ việc tạo thành công Persistent Volume (PV) hoặc chờ việc lập lịch thành công của các Pod liên quan trong trường hợp Gang scheduling.

#heading(level: 5, "Luồng ràng buộc (Bind Thread)")

Luồng ràng buộc đảm nhận việc lưu trữ vĩnh viễn các liên kết giữa Pod và Node trên API server của Kubernetes.

Các Pod được lập lịch theo tuần tự trong luồng lập lịch (schedule thread), nhưng trong các luồng chờ (wait thread) và ràng buộc (bind thread), quá trình lập lịch diễn ra một cách bất đồng bộ và song song. Điều này giúp tối ưu hóa hiệu suất lập lịch và tăng tốc độ triển khai Pod.

#heading(level: 3, "Quá trình lập lịch")

Dưới đây là các giai đoạn cụ thể trong quy trình lập lịch của Kubernetes:

#heading(level: 4, "QueueSort")

Giai đoạn đầu tiên trong quy trình lập lịch là QueueSort, nơi các Pod trong hàng đợi lập lịch được sắp xếp theo độ ưu tiên. Các Pod có PriorityClass cao hơn sẽ được xử lý trước. Kubernetes sử dụng cơ chế này để đảm bảo rằng các Pod quan trọng nhất được lập lịch và triển khai đầu tiên. Điều này giúp cho các ứng dụng có yêu cầu khẩn cấp hoặc cần độ sẵn sàng cao có thể được triển khai mà không bị chậm trễ bởi các Pod ít quan trọng hơn.

#heading(level: 4, "PreFilter")

Sau khi các Pod được xếp thứ tự, Kubernetes thực hiện PreFilter, là một bước kiểm tra nhanh để xác định xem Pod có thể được lập lịch hay không, trước khi thực hiện các bước lọc chi tiết. Giai đoạn này giúp giảm thiểu thời gian và tài nguyên bằng cách kiểm tra các điều kiện đơn giản và quan trọng như việc liệu có bất kỳ Node nào trong cluster hay không, hoặc kiểm tra xem các tài nguyên cơ bản có đủ để khởi tạo Pod hay không. Đây là một bước quan trọng trong việc tối ưu hóa hiệu suất lập lịch, giúp giảm tải cho các bước lọc phức tạp hơn sau này.

#heading(level: 4, "Filter")

Tiếp theo, giai đoạn Filter là nơi các Node không phù hợp sẽ bị loại bỏ. Đây là bước mà Kubernetes kiểm tra các điều kiện chi tiết hơn để đảm bảo rằng Pod chỉ được triển khai lên các Node đáp ứng các yêu cầu nhất định. Các bộ lọc phổ biến trong giai đoạn này bao gồm kiểm tra tài nguyên (CPU, bộ nhớ) có đủ để chạy Pod hay không, kiểm tra NodeAffinity, kiểm tra PodToleratesNodeTaints, và các điều kiện khác như trạng thái sẵn sàng của Node. Giai đoạn này có thể tốn kém về tài nguyên, do đó các bước PreFilter hiệu quả trước đó sẽ giúp giảm thiểu khối lượng công việc trong giai đoạn Filter.

#heading(level: 4, "PreScore")

Sau khi loại bỏ các Node không phù hợp, giai đoạn PreScore sẽ bắt đầu tính toán các dữ liệu trung gian cần thiết cho bước chấm điểm (Scoring). Giai đoạn này chuẩn bị các thông tin về Node, như tài nguyên sử dụng, tình trạng của Node, và các yếu tố khác, để phục vụ cho quá trình chấm điểm chính xác trong giai đoạn tiếp theo.

#heading(level: 4, "Score")

Giai đoạn Score là nơi Kubernetes chấm điểm các Node khả thi dựa trên các yếu tố như tài nguyên sử dụng, khả năng đáp ứng yêu cầu của Pod, và các yếu tố khác. Các chiến lược chấm điểm có thể bao gồm các ưu tiên như tài nguyên ít sử dụng, sự cân bằng giữa các tài nguyên, hoặc các yêu cầu về NodeAffinity. Mỗi Node được gán một điểm số trong khoảng từ 0 đến 100, hoặc có thể là một thang điểm tùy chỉnh. Node có điểm cao nhất sẽ là lựa chọn ưu tiên cho việc lập lịch Pod.

#heading(level: 4, "NormalizeScore")

Sau khi các Node được chấm điểm, bước NormalizeScore được thực hiện để chuẩn hóa điểm số giữa các plugin khác nhau. Bởi vì các plugin scoring có thể sử dụng các thang điểm khác nhau, quá trình chuẩn hóa giúp so sánh các Node một cách công bằng và nhất quán. Việc chuẩn hóa điểm số giúp các quyết định lập lịch trở nên chính xác hơn và đảm bảo tính đồng nhất trong quy trình.

#heading(level: 4, "Reserve")

Giai đoạn Reserve là lúc Kubernetes đánh dấu tài nguyên của Node đã được chọn là "đã được đặt trước". Điều này có nghĩa là các tài nguyên trên Node này sẽ không được sử dụng bởi các Pod khác cho đến khi quá trình lập lịch hoàn tất và Pod được triển khai. Giai đoạn này giúp đảm bảo rằng tài nguyên cần thiết cho Pod sẽ không bị chia sẻ hoặc xung đột trong quá trình triển khai.

#heading(level: 4, "Permit")

Trong bước Permit, các plugin có thể can thiệp vào quá trình lập lịch và quyết định liệu có chấp nhận, từ chối hoặc trì hoãn việc lập lịch hay không. Đây là một cơ chế linh hoạt cho phép các plugin tùy chỉnh can thiệp vào quyết định lập lịch trước khi thực hiện bước PreBind. Ví dụ, plugin có thể yêu cầu một điều kiện bổ sung như đảm bảo rằng Pod không bị gán vào một Node chưa hoàn thành một công việc chuẩn bị nào đó.

#heading(level: 4, "PreBind")

Trước khi Pod được gán vào Node đã chọn, giai đoạn PreBind thực hiện các công việc chuẩn bị cần thiết. Điều này có thể bao gồm các tác vụ như chuẩn bị các volume cần thiết cho Pod, thiết lập các tài nguyên bổ sung như mạng, hoặc xác thực thông tin về Node mà Pod sẽ được triển khai lên. Giai đoạn này đảm bảo rằng tất cả các điều kiện đã sẵn sàng trước khi quá trình gán Pod cho Node bắt đầu.

#heading(level: 4, "Bind")

Giai đoạn cuối cùng trong quy trình lập lịch là Bind. Đây là bước xác nhận chính thức khi kube-scheduler gửi yêu cầu tới API server để gán Pod vào Node đã chọn. Quá trình này kết thúc việc lập lịch và đánh dấu Pod là đã được triển khai. Sau khi Bind thành công, Node đã được chọn sẽ bắt đầu triển khai Pod.

#heading(level: 4, "PostBind")

Cuối cùng, sau khi Pod đã được gán vào Node, Kubernetes thực hiện PostBind, nơi các công việc hậu kỳ được thực hiện. Điều này có thể bao gồm việc cập nhật bộ nhớ cache nội bộ của hệ thống hoặc tiến hành các tác vụ giám sát để theo dõi tình trạng của Pod trên Node. Giai đoạn này giúp hoàn tất quá trình lập lịch và duy trì thông tin hệ thống luôn cập nhật.

#heading(level: 2, "Các phương pháp điều khiển lập lịch Pod")
Trong Kubernetes, kube-scheduler thường đủ thông minh để tự động lựa chọn các Node phù hợp nhằm đảm bảo hiệu suất và sự phân bố hợp lý của các Pod trong cụm. Tuy nhiên, trong nhiều tình huống thực tế, người dùng – đặc biệt là các quản trị viên hệ thống hoặc các kỹ sư vận hành – muốn kiểm soát chính xác nơi một Pod sẽ chạy. Mục tiêu có thể là để đảm bảo tuân thủ các chính sách bảo mật, tận dụng phần cứng chuyên dụng như GPU hoặc SSD, phân tán ứng dụng theo vùng địa lý để tăng khả năng chống lỗi, hoặc cô lập workload để tránh can nhiễu. Kubernetes hỗ trợ nhiều công cụ và cơ chế để đạt được điều đó, từ các cách đơn giản như nodeSelector đến các cơ chế phức tạp như taints/tolerations và affinity/anti-affinity. Dưới đây là phân tích chi tiết từng cơ chế:

#heading(level: 3, "Node Selector")
nodeSelector là cơ chế cơ bản và đơn giản nhất để kiểm soát việc lập lịch Pod. Nó hoạt động bằng cách chỉ định rằng Pod chỉ nên được lập lịch trên các Node có nhãn (label) phù hợp. Trong cấu hình Pod, thêm trường nodeSelector cùng với một tập các khóa-giá trị, ví dụ như:
```yaml
...
nodeSelector:
  disktype: ssd
...
```
Kubernetes sẽ chỉ lập lịch Pod này lên các Node có nhãn disktype=ssd. Cách làm này phù hợp với các yêu cầu đơn giản như chỉ định một nhóm máy chuyên dụng để xử lý công việc nặng, hoặc gán workload nhạy cảm lên các Node riêng biệt.

Tuy nhiên, nodeSelector có những hạn chế. Nó chỉ hỗ trợ kiểm tra chính xác các nhãn theo kiểu “bằng nhau” (equality-based) và không thể kết hợp điều kiện phức tạp (ví dụ: nhãn A tồn tại nhưng nhãn B không tồn tại). Hơn nữa, các điều kiện là bắt buộc – nếu không có Node nào phù hợp, Pod sẽ không được lập lịch.


#heading(level: 3, "Node Affinity và Anti-Affinity")
Để khắc phục hạn chế của nodeSelector, Kubernetes cung cấp nodeAffinity, một tính năng mạnh mẽ hơn, cho phép người dùng viết các ràng buộc phức tạp hơn dựa trên nhãn của Node. Node Affinity hỗ trợ hai loại điều kiện chính:

requiredDuringSchedulingIgnoredDuringExecution: đây là điều kiện bắt buộc. Nếu không có Node nào phù hợp, Pod sẽ không được lập lịch.

preferredDuringSchedulingIgnoredDuringExecution: đây là điều kiện ưu tiên. Nếu có Node phù hợp thì Pod sẽ được lập lịch theo ưu tiên này, còn không thì vẫn lập lịch bình thường.

Ví dụ, có thể viết điều kiện như sau:

```yaml
...
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: zone
          operator: In
          values:
            - us-east-1a
            - us-east-1b
...
```
Khác với nodeSelector, nodeAffinity hỗ trợ các toán tử như In, NotIn, Exists, DoesNotExist, cho phép định nghĩa logic linh hoạt hơn.

Ngoài ra, còn có Pod affinity và anti-affinity – cho phép lập lịch các Pod dựa vào nhãn của các Pod khác. Ví dụ, có thể yêu cầu một Pod mới phải được lập lịch cùng Node với các Pod mang nhãn app=web (affinity), hoặc tránh các Node có nhiều Pod app=cache đang chạy (anti-affinity). Điều này rất hữu ích khi ta muốn:

Gom nhóm các Pod để giảm độ trễ trong giao tiếp giữa chúng.

Phân tán các bản sao Pod để giảm rủi ro mất mát do lỗi phần cứng.


#heading(level: 3, "Taints và Tolerations")
Taints và Tolerations là cơ chế điều khiển lập lịch theo hướng loại trừ mặc định: đánh dấu (taint) một Node để ngăn không cho Pod được lập lịch lên đó, trừ khi Pod có “toleration” tương ứng. Điều này rất hữu ích trong các tình huống như:

Node chuyên dụng cho workload đặc biệt (như GPU, dữ liệu bảo mật).

Node đang trong quá trình bảo trì, không muốn Pod mới được lập lịch vào.

Một ví dụ về taint:

```bash
kubectl taint nodes node1 key=value:NoSchedule
```
Pod nào không có tolerations tương ứng sẽ không được lập lịch lên node1. Trong manifest của Pod, ta thêm phần:

```yaml
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"
```
Kết hợp taints và affinity sẽ cho phép cô lập workload một cách linh hoạt và hiệu quả.


#heading(level: 3, "Pod Topology Spread Constraints")

Đây là một tính năng nâng cao được giới thiệu để đảm bảo các Pod được phân bố đều trên các vùng hoặc nhóm Node, giúp tăng khả năng chống chịu lỗi. Ví dụ, nếu ta triển khai 10 bản sao Pod, ta có thể yêu cầu Kubernetes phân bố chúng đều trên 3 vùng khả dụng (Availability Zones), thay vì đặt tất cả lên một vùng.

Cấu hình sử dụng topologySpreadConstraints, ví dụ:

```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: ScheduleAnyway
  labelSelector:
    matchLabels:
      app: my-app
```
Điều này giúp đảm bảo rằng hệ thống phân tán của người dùng hoạt động ổn định và giảm thiểu tác động nếu một vùng (zone) bị lỗi.

Tóm lại, Kubernetes cung cấp một loạt công cụ đa dạng để điều khiển quá trình lập lịch Pod một cách chi tiết và có kiểm soát. Tùy vào yêu cầu kỹ thuật, hạ tầng và chính sách tổ chức, người dùng có thể chọn các công cụ phù hợp hoặc kết hợp nhiều cơ chế lại để đạt được hiệu quả tối ưu nhất cho việc vận hành ứng dụng trên Kubernetes.

#heading(level: 2, "Các chiến lược nâng cao trong lập lịch Kubernetes")

Các chiến lược nâng cao trong lập lịch Kubernetes
Trong Kubernetes, việc lập lịch không chỉ đơn giản là phân phối các Pod vào các Node, mà còn liên quan đến việc tối ưu hóa tài nguyên, giảm độ trễ, tăng khả năng chịu lỗi và bảo mật cho ứng dụng. Để đáp ứng các yêu cầu phức tạp và tăng tính linh hoạt trong việc triển khai ứng dụng, Kubernetes cung cấp một số chiến lược nâng cao trong lập lịch. Ba chiến lược quan trọng nhất trong số đó là Topology Spread Constraints, Pod Priority và Preemption, và Scheduling Policies và Scheduling Profiles (Plugin).

#heading(level: 3, "Topology Spread Constraints")

Topology Spread Constraints giúp người dùng kiểm soát cách các Pod được phân phối trên các Node, vùng (availability zones), hay các khu vực lỗi trong cluster. Mục đích chính của chiến lược này là giảm thiểu rủi ro khi một khu vực hoặc Node gặp sự cố, giúp ứng dụng duy trì tính khả dụng cao và chịu lỗi tốt hơn.

Khi ta triển khai một ứng dụng có yêu cầu độ sẵn sàng cao hoặc có thể gặp phải các sự cố hạ tầng, việc sử dụng Topology Spread Constraints sẽ giúp phân tán các Pod một cách hợp lý. Ví dụ, trong môi trường đa vùng dữ liệu, ta có thể cấu hình các Pod sao cho chúng được phân bố đều giữa các vùng để tránh tình trạng mất dịch vụ khi một vùng bị gián đoạn.

Kubernetes hỗ trợ cấu hình phân phối này qua các thuộc tính như maxSkew, topologyKey, và whenUnsatisfiable, giúp người dùng định nghĩa các ràng buộc về độ phân tán mà không làm giảm khả năng chịu lỗi của hệ thống. Các chiến lược này không chỉ giúp cải thiện khả năng chịu lỗi mà còn giúp tối ưu hóa hiệu suất và tài nguyên cho các ứng dụng phân tán.

#heading(level: 3, "Pod Priority và Preemption")

Pod Priority và Preemption là hai cơ chế quan trọng giúp Kubernetes quản lý các Pod trong điều kiện tài nguyên hạn chế. Mỗi Pod trong Kubernetes có thể được gán một mức độ Priority, giúp xác định độ quan trọng của nó đối với hệ thống. Các Pod có Priority cao hơn sẽ có quyền sử dụng tài nguyên khi có sự tranh chấp tài nguyên.

Khi tài nguyên trong cluster không đủ để chạy tất cả các Pod, cơ chế Preemption sẽ được kích hoạt. Kubernetes sẽ hủy các Pod có Priority thấp hơn để tạo không gian cho các Pod có Priority cao hơn. Cơ chế này rất hữu ích trong các tình huống có tài nguyên hạn chế, nơi các dịch vụ quan trọng cần được ưu tiên để chạy.

Cơ chế Pod Priority và Preemption giúp người dùng kiểm soát việc phân phối tài nguyên giữa các Pod dựa trên mức độ quan trọng của chúng. Ví dụ, trong môi trường sản xuất, các dịch vụ cần thiết cho hoạt động của hệ thống (như dịch vụ cơ sở dữ liệu hoặc dịch vụ xử lý thanh toán) có thể được gán Priority cao để đảm bảo rằng chúng sẽ luôn có đủ tài nguyên ngay cả khi hệ thống bị thiếu tài nguyên.

#heading(level: 3, "Scheduling Policies và Scheduling Profiles (Plugin)")

Scheduling Policies và Scheduling Profiles cung cấp một cách để tùy chỉnh quy trình lập lịch trong Kubernetes. Với Scheduling Policies, người dùng có thể cấu hình các Predicates để lọc các Node phù hợp và Priorities để chấm điểm các Node, từ đó quyết định nơi nào phù hợp để triển khai Pod.

Trong khi đó, Scheduling Profiles cung cấp một cấu trúc mô-đun cho phép triển khai các Plugins tại các giai đoạn khác nhau trong quy trình lập lịch. Các giai đoạn này bao gồm: QueueSort, Filter, Score, Bind, Reserve, Permit, và nhiều giai đoạn khác. Người dùng có thể tùy chỉnh các giai đoạn lập lịch này để đáp ứng các yêu cầu đặc biệt về cách thức các Pod được lập lịch, từ việc lọc các Node đến việc tính điểm và quyết định việc gán Pod vào Node.

Cấu trúc của Scheduling Profiles giúp người dùng có thể triển khai nhiều bộ lập lịch với các chiến lược khác nhau, hoặc thậm chí triển khai các bộ lập lịch tùy chỉnh cho các tình huống đặc thù. Việc sử dụng Plugin trong Kubernetes giúp mở rộng khả năng lập lịch của hệ thống, đáp ứng những yêu cầu phức tạp hơn mà bộ lập lịch mặc định không thể xử lý.

Các chiến lược Scheduling Policies và Scheduling Profiles mang lại sự linh hoạt và khả năng mở rộng cao trong việc điều chỉnh hành vi lập lịch của Kubernetes. Chúng cho phép người dùng triển khai các giải pháp lập lịch tùy chỉnh để tối ưu hóa việc phân bổ tài nguyên, đáp ứng các yêu cầu đặc biệt của ứng dụng hoặc hạ tầng.

Các chiến lược nâng cao này không chỉ giúp Kubernetes trở thành một hệ thống lập lịch mạnh mẽ mà còn tăng cường khả năng mở rộng và chịu lỗi của các ứng dụng triển khai trên đó. Topology Spread Constraints giúp tối ưu hóa sự phân bố tài nguyên, Pod Priority và Preemption giúp quản lý tài nguyên trong điều kiện thiếu hụt, và Scheduling Policies & Profiles cung cấp sự linh hoạt để tùy chỉnh hành vi lập lịch cho các yêu cầu đặc biệt.


#heading(level: 2, "Ví dụ chi tiết về một quyết định lập lịch")
Giả sử chúng ta có một Pod cần 2 CPU cores và 4GB RAM, có nodeSelector yêu cầu disk-type=ssd, và có affinity ưu tiên gần các Pod có nhãn app=database. Cluster có 5 Node:

- Node A: 4 CPU, 16GB RAM, có nhãn disk-type=ssd, đang chạy 1 Pod với nhãn app=database
- Node B: 4 CPU, 8GB RAM, có nhãn disk-type=ssd, không có Pod app=database
- Node C: 8 CPU, 32GB RAM, không có nhãn disk-type=ssd
- Node D: 2 CPU, 16GB RAM, có nhãn disk-type=ssd
- Node E: 4 CPU, 16GB RAM, có nhãn disk-type=ssd, đang chạy 2 Pod với nhãn app=database nhưng CPU đang sử dụng cao (3.5/4 cores)

Trong quá trình lọc:

- Node C bị loại vì không có nhãn disk-type=ssd
- Node D bị loại vì không đủ CPU (cần 2 cores)

Trong quá trình chấm điểm:

- Node A: Điểm cao vì đủ tài nguyên, đáp ứng nodeSelector, và có affinity với database
- Node B: Điểm trung bình, đáp ứng nodeSelector nhưng không có affinity với database
- Node E: Điểm thấp vì mặc dù đáp ứng nodeSelector và có affinity mạnh với database, nhưng CPU đã gần đạt ngưỡng

Kết quả: Node A được chọn làm nơi đặt Pod.


#heading(level: 2, "Kết luận")
Bộ lập lịch là một phần thiết yếu trong hoạt động của Kubernetes. Thông qua quá trình lọc và chấm điểm, kube-scheduler đảm bảo rằng mỗi Pod được đặt ở vị trí tối ưu nhất trong cluster. Việc hiểu rõ cơ chế hoạt động của kube-scheduler không chỉ giúp người dùng vận hành hệ thống hiệu quả mà còn mở ra khả năng tối ưu hóa hoặc tùy chỉnh phù hợp với đặc thù ứng dụng hoặc hạ tầng của doanh nghiệp.

