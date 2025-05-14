

- Mẫu slide: https://docs.google.com/presentation/d/1WAPssIW7lI4LDNAQzGx_JedWtxVovks8mf_nRanMAGM/edit?usp=sharing

- Slide: https://docs.google.com/presentation/d/1H085LdWYNDmUtVnK3sb3IBb9n0pjZPynA-F_iVeaKQs/edit?usp=sharing

- Xem slide mẫu cop qua slide đang làm xong sửa lại nội dung tương ứng.

Slide 1: Slide Tiêu Đề

Nội dung:

ĐẠI HỌC QUỐC GIA HÀ NỘI - TRƯỜNG ĐẠI HỌC CÔNG NGHỆ (Logo trường nếu có)

BÁO CÁO BÀI TẬP LỚN

BỘ LẬP LỊCH TÙY CHỈNH VÀ THUẬT TOÁN CẤP PHÁT TÀI NGUYÊN CHO KUBERNETES

Nhóm 1

Môn học: INT3310 1 - Quản trị mạng

Giảng viên hướng dẫn: TS. Dương Lê Minh

Sinh viên thực hiện: (Liệt kê tên các thành viên)

HÀ NỘI - 2025

Lời thoại:

"Kính chào thầy và các bạn. Chúng em là Nhóm 1. Hôm nay, nhóm chúng em xin trình bày báo cáo bài tập lớn môn Quản trị mạng với đề tài: 'Bộ Lập Lịch Tùy Chỉnh và Thuật Toán Cấp Phát Tài Nguyên Cho Kubernetes'."

(Nếu muốn, có thể giới thiệu nhanh từng thành viên)

Slide 2: Nội Dung Chính (Agenda)

Nội dung:

Giới thiệu: Kubernetes & Nhu cầu Lập lịch

Bộ Lập Lịch Mặc Định của Kubernetes (kube-scheduler)

Hạn chế & Lý do cần Bộ Lập Lịch Tùy Chỉnh

Bộ Lập Lịch Tùy Chỉnh của Nhóm:

Kiến trúc & Các Thành phần Chính

Logic Lập Lịch Cốt lõi (Lọc & Chấm điểm với Số liệu Thời gian Thực)

Các Tính năng & Lợi ích Chính

Xem trước Demo

Kết luận & Hỏi Đáp

Lời thoại:

"Trong buổi trình bày hôm nay, chúng ta sẽ cùng tìm hiểu các nội dung chính sau: Đầu tiên là phần giới thiệu chung về Kubernetes và tầm quan trọng của việc lập lịch. Tiếp theo, chúng ta sẽ xem xét bộ lập lịch mặc định và những hạn chế của nó. Từ đó, chúng ta sẽ đi đến lý do cần một bộ lập lịch tùy chỉnh và giới thiệu giải pháp của nhóm em, bao gồm kiến trúc, logic hoạt động. Sau đó là các tính năng, lợi ích, phần xem trước demo và cuối cùng là kết luận và phần hỏi đáp."

Slide 3: Giới Thiệu - Kubernetes & Thách Thức Lập Lịch (2 phút)

Nội dung:

Ngắn gọn: Sự phát triển của Microservices & Containers (Docker).

Kubernetes: Điều phối ứng dụng container hóa ở quy mô lớn.

Khái niệm cốt lõi K8s: Pods (đơn vị triển khai nhỏ nhất).

Vấn đề Lập lịch: Các Pod mới nên chạy ở đâu trong cluster?

Cần xem xét: dung lượng node, yêu cầu Pod, các chính sách.

Hình ảnh: Sơ đồ đơn giản của một K8s cluster (Control Plane, Nodes với các Pods). Nổi bật thành phần Scheduler trong Control Plane.

Lời thoại:

"Như chúng ta đã biết, xu hướng microservices và công nghệ container, đặc biệt là Docker, đã thay đổi cách chúng ta phát triển và triển khai ứng dụng. Kubernetes ra đời như một giải pháp mạnh mẽ để điều phối các ứng dụng container hóa này. Trong Kubernetes, Pod là đơn vị nhỏ nhất có thể triển khai. Và một câu hỏi quan trọng đặt ra là: khi một Pod mới được tạo, nó nên được chạy trên node nào trong cluster? Đây chính là bài toán lập lịch, đòi hỏi phải cân nhắc nhiều yếu tố như dung lượng của node, yêu cầu của Pod và các chính sách của hệ thống."

Slide 4: Bộ Lập Lịch Mặc Định của Kubernetes (kube-scheduler) (2 phút)

Nội dung:

kube-scheduler: "Bộ não" đưa ra quyết định vị trí đặt Pod.

Quy trình hai giai đoạn:

Lọc (Filtering - Predicates):

Loại bỏ các node không thể chạy Pod.

Kiểm tra: Yêu cầu tài nguyên (CPU, memory), node selectors, taints/tolerations, affinity (luật cứng).

Chấm điểm (Scoring - Priorities):

Xếp hạng các node phù hợp dựa trên các chính sách đã cấu hình (ví dụ: phân tán Pod, ưu tiên node ít tải dựa trên yêu cầu).

Binding: Gán Pod cho node có điểm cao nhất.

Hình ảnh: Luồng đơn giản: Unscheduled Pod -> [Filtering] -> Feasible Nodes -> [Scoring] -> Best Node -> [Binding].

Lời thoại:

"Để giải quyết bài toán này, Kubernetes cung cấp một thành phần mặc định gọi là kube-scheduler. Đây chính là 'bộ não' đưa ra các quyết định đặt Pod. Quy trình của kube-scheduler gồm hai giai đoạn chính. Đầu tiên là Lọc, nơi nó loại bỏ các node không đáp ứng được yêu cầu của Pod, ví dụ như không đủ tài nguyên, không khớp node selector, hoặc bị 'taint' mà Pod không 'tolerate'. Sau giai đoạn lọc, chúng ta có một danh sách các node khả thi. Giai đoạn thứ hai là Chấm điểm, kube-scheduler sẽ xếp hạng các node này dựa trên các chính sách ưu tiên, ví dụ như ưu tiên các node đang có ít Pod hơn hoặc có tài nguyên yêu cầu còn trống nhiều. Cuối cùng, Pod sẽ được Binding (gán) vào node có điểm số cao nhất."

Slide 5: Hạn Chế & Lý do cần Bộ Lập Lịch Tùy Chỉnh (1.5 phút)

Nội dung:

Bộ lập lịch mặc định chủ yếu dựa vào yêu cầu tài nguyên requests của Pod (thông số tĩnh).

Vấn đề: Không xem xét mức sử dụng tài nguyên thực tế, thời gian thực của node.

Một node có thể có tải yêu cầu thấp nhưng CPU/memory thực tế đang được sử dụng cao bởi các Pod hiện có.

Có thể dẫn đến việc đặt Pod không tối ưu, ví dụ: đặt Pod mới vào các node đã bận.

Cơ hội: Bộ lập lịch tùy chỉnh có thể đưa ra quyết định sáng suốt hơn bằng cách sử dụng số liệu trực tiếp.

Lời thoại:

"Mặc dù kube-scheduler hoạt động hiệu quả, nó có một hạn chế chính: nó chủ yếu dựa vào thông số requests tài nguyên được khai báo tĩnh trong Pod. Điều này có nghĩa là nó không hoàn toàn nhận biết được tình trạng tải thực tế trên các node. Ví dụ, một node có thể có tổng requests thấp, nhưng các Pod trên đó lại đang sử dụng rất nhiều CPU hoặc memory thực tế. Việc này có thể dẫn đến quyết định lập lịch không tối ưu, chẳng hạn như đặt một Pod mới lên một node vốn đã rất bận rộn. Đây chính là cơ hội để một bộ lập lịch tùy chỉnh, có khả năng sử dụng các số liệu thời gian thực, phát huy vai trò của mình."

Slide 6: Bộ Lập Lịch Tùy Chỉnh của Nhóm - Mục tiêu & Kiến trúc (2.5 phút)

Nội dung:

Mục tiêu Dự án: Cải thiện việc đặt Pod bằng cách tích hợp:

Số liệu node thời gian thực (bộ nhớ khả dụng thực tế, CPU nhàn rỗi).

Ưu tiên affinity do Pod định nghĩa.

Tổng quan Kiến trúc:

Bộ Lập Lịch Tùy Chỉnh (ứng dụng Go): Theo dõi K8s API để tìm Pod mới (schedulerName: custom-scheduler).

Kubernetes API Server: Nguồn thông tin Pod/Node, đích để binding.

Prometheus: Tổng hợp số liệu thời gian thực.

Node Exporter (DaemonSet): Cung cấp số liệu cấp node trên mỗi node.

Hình ảnh: Sơ đồ kiến trúc tổng quan (từ mục 3.1.1 trong báo cáo). Minh họa luồng tương tác: Pod được tạo -> Bộ Lập Lịch Tùy Chỉnh phát hiện -> Truy vấn K8s API & Prometheus -> Đưa ra quyết định -> Binding thông qua K8s API.

Lời thoại:

"Với những hạn chế đó, mục tiêu của dự án nhóm em là phát triển một bộ lập lịch tùy chỉnh nhằm cải thiện việc phân bổ Pod bằng cách tích hợp hai yếu tố chính: thứ nhất là các số liệu thời gian thực của node như bộ nhớ khả dụng và CPU nhàn rỗi, và thứ hai là tôn trọng các ưu tiên affinity do Pod định nghĩa.

Về kiến trúc, giải pháp của chúng em bao gồm các thành phần chính sau:

Trái tim của hệ thống là Bộ Lập Lịch Tùy Chỉnh, một ứng dụng viết bằng Go, có nhiệm vụ theo dõi các Pod mới yêu cầu lập lịch tùy chỉnh.

Nó tương tác với Kubernetes API Server để lấy thông tin về Pod, Node và thực hiện việc binding.

Để có được số liệu thời gian thực, chúng em sử dụng Prometheus để tổng hợp dữ liệu.

Và cuối cùng, Node Exporter, chạy dưới dạng DaemonSet trên mỗi node, chịu trách nhiệm thu thập và cung cấp các số liệu chi tiết của node cho Prometheus."

(Chỉ vào sơ đồ để giải thích luồng) "Khi một Pod mới được tạo và yêu cầu bộ lập lịch tùy chỉnh, scheduler của chúng em sẽ phát hiện, sau đó truy vấn thông tin từ API Server và dữ liệu thực tế từ Prometheus để đưa ra quyết định node nào phù hợp nhất, và cuối cùng thực hiện binding Pod vào node đó."

Slide 7: Bộ Lập Lịch Tùy Chỉnh - Logic Cốt lõi: Lọc (1.5 phút)

Nội dung:

1. Phát hiện Pod: Theo dõi các Pod có spec.schedulerName: custom-scheduler và chưa có spec.nodeName.

2. Lọc (Predicates): Tương tự như mặc định, nhưng được thực hiện bởi code của nhóm.

Kiểm tra pod.Spec.NodeSelector.

Kiểm tra pod.Spec.Tolerations với taints của Node.

Kiểm tra yêu cầu tài nguyên requests (CPU, Memory) với tài nguyên allocatable của Node.

(Ngắn gọn đề cập yêu cầu cứng của Node Affinity nếu có, hoặc để dành cho phần chấm điểm).

Lời thoại:

"Quy trình lập lịch tùy chỉnh của chúng em cũng bắt đầu bằng việc phát hiện các Pod cần được xử lý, tức là những Pod có khai báo schedulerName là custom-scheduler và chưa được gán vào node nào.

Tiếp theo là giai đoạn Lọc, tương tự như bộ lập lịch mặc định. Ở giai đoạn này, chúng em sẽ loại bỏ các node không phù hợp dựa trên các tiêu chí như nodeSelector của Pod, khả năng 'tolerate' các 'taint' của node, và quan trọng là kiểm tra xem node có đủ tài nguyên CPU và Memory theo requests của Pod hay không. Mục tiêu là tìm ra một danh sách các node có thể chạy được Pod này."

Slide 8: Bộ Lập Lịch Tùy Chỉnh - Logic Cốt lõi: Chấm điểm với Số liệu Thời gian Thực (3 phút)

Nội dung:

3. Chấm điểm (Priorities) - Phần "Thông minh":

Với mỗi node đã lọc (khả thi):

Truy vấn Prometheus:

node_memory_MemAvailable_bytes (bộ nhớ khả dụng thực tế).

avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) (số lõi CPU nhàn rỗi trung bình).

Tính điểm (thang 0-10):

Điểm Bộ nhớ: Cao hơn nếu có nhiều bộ nhớ khả dụng.

Điểm CPU: Cao hơn nếu có nhiều CPU nhàn rỗi.

Điểm Node Affinity: Dựa trên preferredDuringSchedulingIgnoredDuringExecution (ví dụ: weight cho các label khớp).

Tổng điểm có Trọng số: (Weight_Mem * MemScore) + (Weight_CPU * CPUScore) + (Weight_Affinity ** AffinityScore)

Các trọng số có thể cấu hình qua biến môi trường (ví dụ: SCORE_WEIGHT_MEM).

Hình ảnh: Có thể là một đoạn nhỏ của truy vấn PromQL hoặc công thức chấm điểm.

Lời thoại:

"Đây là phần cốt lõi và là điểm khác biệt chính của bộ lập lịch tùy chỉnh: giai đoạn Chấm điểm. Sau khi có danh sách các node khả thi, chúng em sẽ tính điểm cho từng node.

Điểm đặc biệt ở đây là chúng em truy vấn trực tiếp Prometheus để lấy các số liệu thời gian thực. Cụ thể là lượng bộ nhớ thực sự còn trống trên node (node_memory_MemAvailable_bytes) và tỷ lệ CPU trung bình đang nhàn rỗi (avg ... rate(node_cpu_seconds_total{mode="idle"})).

Dựa trên các số liệu này, chúng em tính ra các điểm thành phần: Điểm Bộ nhớ và Điểm CPU, theo thang điểm từ 0 đến 10 – node nào có nhiều tài nguyên thực tế hơn sẽ có điểm cao hơn. Ngoài ra, chúng em cũng tính Điểm Node Affinity nếu Pod có khai báo các ưu tiên về node.

Cuối cùng, Tổng điểm của mỗi node sẽ được tính bằng cách kết hợp các điểm thành phần này với các trọng số tương ứng. Các trọng số này có thể dễ dàng cấu hình thông qua biến môi trường, cho phép người quản trị tùy chỉnh mức độ ưu tiên cho từng yếu tố."

Slide 9: Bộ Lập Lịch Tùy Chỉnh - Logic Cốt lõi: Lựa chọn & Binding (1 phút)

Nội dung:

4. Lựa chọn Node:

Node có tổng điểm có trọng số cao nhất sẽ được chọn.

Logic phá vỡ thế hòa (tie-breaking) (ví dụ: ưu tiên bộ nhớ cao hơn nếu điểm bằng nhau).

5. Binding:

Bộ lập lịch tùy chỉnh tạo một đối tượng Binding.

Gửi (POST) đối tượng Binding đến Kubernetes API Server.

Kubelet trên node được chọn sau đó sẽ khởi chạy Pod.

Báo cáo Sự kiện: Tạo các đối tượng Event của Kubernetes (ví dụ: "Scheduled", "FailedScheduling") để dễ theo dõi.

Lời thoại:

"Sau khi đã chấm điểm tất cả các node khả thi, bộ lập lịch sẽ Lựa chọn Node có tổng điểm cao nhất. Trong trường hợp có nhiều node bằng điểm, chúng em cũng có logic 'tie-breaking', ví dụ như ưu tiên node có nhiều bộ nhớ hơn.

Khi node tốt nhất đã được xác định, bộ lập lịch tùy chỉnh sẽ thực hiện thao tác Binding. Nó tạo một đối tượng Binding đặc biệt và gửi đến API Server. API Server sau đó sẽ cập nhật trạng thái của Pod, và Kubelet trên node được chọn sẽ nhận biết và khởi chạy Pod.

Đồng thời, để tăng khả năng quan sát, bộ lập lịch của chúng em cũng tạo ra các Kubernetes Events, ví dụ như 'Scheduled' khi thành công hoặc 'FailedScheduling' khi có lỗi."

Slide 10: Các Tính năng & Lợi ích Chính (2 phút)

Nội dung:

Lập lịch Nhận biết Tài nguyên: Xem xét tải thực tế của node, không chỉ yêu cầu tĩnh.

Dẫn đến sử dụng tài nguyên tốt hơn và có thể ngăn ngừa quá tải node.

Chấm điểm Tùy chỉnh: Các trọng số cho bộ nhớ, CPU, và affinity có thể được điều chỉnh.

Tôn trọng Các Cấu trúc K8s Tiêu chuẩn:

nodeSelector, taints/tolerations, nodeAffinity.

Khả năng Quan sát: Thông qua Kubernetes Events và logs.

Tích hợp Prometheus: Tận dụng công cụ giám sát được sử dụng rộng rãi.

Lời thoại:

"Vậy, bộ lập lịch tùy chỉnh của chúng em mang lại những lợi ích gì?

Đầu tiên và quan trọng nhất là Lập lịch Nhận biết Tài nguyên: nó xem xét tải thực tế trên node, giúp sử dụng tài nguyên hiệu quả hơn và tránh tình trạng quá tải.

Thứ hai, Chấm điểm Tùy chỉnh cho phép điều chỉnh các trọng số, mang lại sự linh hoạt cao.

Nó vẫn Tôn trọng đầy đủ các cơ chế lập lịch tiêu chuẩn của Kubernetes như nodeSelector, taints/tolerations, và nodeAffinity.

Khả năng Quan sát được đảm bảo thông qua Events và logs.

Và cuối cùng, việc Tích hợp với Prometheus giúp tận dụng một hệ sinh thái giám sát mạnh mẽ và phổ biến."

Slide 11: Ảnh chụp Cấu hình & Triển khai (1 phút)

Nội dung:

Khai báo Pod: spec.schedulerName: custom-scheduler

Triển khai Bộ Lập Lịch:

Chạy dưới dạng Deployment trong namespace kube-system.

RBAC: ServiceAccount, ClusterRole, ClusterRoleBinding cho các quyền API cần thiết.

Biến môi trường cho các trọng số chấm điểm (ví dụ: SCORE_WEIGHT_MEM: "0.6").

Stack Giám sát: Prometheus & Node Exporter phải được triển khai.

Hình ảnh: Đoạn mã YAML minh họa schedulerName trong Pod. Đoạn mã YAML minh họa biến môi trường trong deployment của scheduler.

Lời thoại:

"Để sử dụng bộ lập lịch tùy chỉnh này, người dùng chỉ cần chỉ định spec.schedulerName: custom-scheduler trong file manifest của Pod.

Bản thân bộ lập lịch được triển khai dưới dạng một Deployment trong namespace kube-system, với các quyền RBAC cần thiết để tương tác với API server. Các trọng số cho thuật toán chấm điểm cũng được cấu hình thông qua biến môi trường ngay trong file deployment này.

Và dĩ nhiên, một hệ thống giám sát với Prometheus và Node Exporter là điều kiện cần để bộ lập lịch có thể hoạt động."

Slide 12: Xem trước Demo (1.5 phút)

Nội dung:

Những gì chúng ta sẽ demo trực tiếp trên GKE:

Nhận biết Tài nguyên:

Pods có yêu cầu cao nhưng sử dụng thực tế thấp (sleep.yaml).

Pods có yêu cầu thấp nhưng sử dụng thực tế cao (sysbench.yaml).

So sánh vị trí đặt Pod: Bộ lập lịch mặc định vs. Bộ Lập Lịch Tùy Chỉnh (kỳ vọng bộ lập lịch tùy chỉnh sẽ cân bằng tốt hơn dựa trên tải thực tế).

Node Selector: Bộ lập lịch tùy chỉnh tôn trọng nodeSelector.

Taints & Tolerations: Bộ lập lịch tùy chỉnh tôn trọng taints.

Node Affinity: Bộ lập lịch tùy chỉnh xem xét preferredDuringScheduling...

Lời thoại:

"Tiếp theo đây, nhóm em xin được phép demo trực tiếp trên Google Kubernetes Engine một số kịch bản để minh họa hoạt động của bộ lập lịch tùy chỉnh.

Đầu tiên, chúng em sẽ cho thấy khả năng Nhận biết Tài nguyên bằng cách triển khai các Pod có yêu cầu tài nguyên khác biệt so với mức sử dụng thực tế, và so sánh quyết định của bộ lập lịch tùy chỉnh với bộ lập lịch mặc định.

Sau đó, chúng em sẽ demo việc bộ lập lịch tùy chỉnh tôn trọng các cơ chế như Node Selector, Taints và Tolerations, cũng như Node Affinity."

(Chuyển sang Demo Trực tiếp - 5 phút)

Slide 13: Kết Luận (1 phút)

Nội dung:

Bộ lập lịch mặc định của Kubernetes hiệu quả nhưng có hạn chế trong môi trường động.

Bộ lập lịch tùy chỉnh của nhóm đã chứng minh khả năng cải thiện việc đặt Pod bằng cách tích hợp số liệu thời gian thực từ Prometheus.

Nó cung cấp sự linh hoạt trong khi vẫn tôn trọng các nguyên tắc lập lịch tiêu chuẩn của Kubernetes.

Cách tiếp cận này dẫn đến việc sử dụng tài nguyên tốt hơn và hiệu quả cluster cao hơn.

Lời thoại:

"Qua phần trình bày và demo vừa rồi, có thể thấy rằng mặc dù bộ lập lịch mặc định của Kubernetes rất mạnh mẽ, nó vẫn có những hạn chế nhất định, đặc biệt trong các môi trường có tải thay đổi động.

Bộ lập lịch tùy chỉnh mà nhóm em phát triển đã cho thấy tiềm năng cải thiện việc phân bổ Pod bằng cách tích hợp các số liệu thời gian thực từ Prometheus, đồng thời vẫn đảm bảo sự linh hoạt và tuân thủ các tiêu chuẩn của Kubernetes.

Chúng em tin rằng cách tiếp cận này có thể giúp tối ưu hóa việc sử dụng tài nguyên và nâng cao hiệu quả hoạt động của cluster."


Slide 15: Hỏi Đáp / Cảm ơn

Nội dung:

"Cảm ơn thầy và các bạn đã lắng nghe!"

"Câu hỏi?"

Link đến kho GitHub: https://github.com/HynDuf/custom-kubernetes-scheduler

Lời thoại:

"Phần trình bày của nhóm em đến đây là kết thúc. Chúng em xin chân thành cảm ơn thầy và các bạn đã chú ý lắng nghe. Nếu có bất kỳ câu hỏi nào, xin mời thầy và các bạn đặt câu hỏi ạ."

(Hiển thị link GitHub) "Mã nguồn của dự án đã được chúng em công khai trên GitHub tại địa chỉ này."

Lưu ý khi Trình bày:

Luyện tập kỹ về thời gian. 20 phút là khá ngắn.

Tập trung vào "tại sao" và "giá trị mang lại." Tại sao nhóm bạn xây dựng cái này? Nó giải quyết vấn đề gì tốt hơn so với mặc định?

Các slide về kiến trúc và logic chấm điểm là rất quan trọng. Dành đủ thời gian cho chúng.

Giữ hình ảnh rõ ràng và đơn giản. Đừng nhồi nhét quá nhiều thông tin vào một slide.

Nói rõ ràng, tự tin và nhiệt tình!

Chúc nhóm bạn có một buổi báo cáo thành công!