#{
  show heading: none
  heading(numbering: none)[Tóm tắt]
}
#align(center, text(13pt, strong("TÓM TẮT")))
#v(0.2cm)

#set text(12pt)
*Tóm tắt*:  Trong bối cảnh các hệ thống ứng dụng ngày càng phức tạp và đòi hỏi cao về hiệu suất cũng như khả năng chịu lỗi, việc điều phối và phân bổ tài nguyên trong Kubernetes đóng vai trò then chốt. Bộ lập lịch mặc định của Kubernetes, kube-scheduler, tuy hiệu quả nhưng chủ yếu dựa trên yêu cầu tài nguyên tĩnh của pod. Điều này đôi khi chưa tối ưu trong các môi trường động với tải thay đổi liên tục. Dự án này giới thiệu một giải pháp bộ lập lịch Kubernetes tùy chỉnh, được phát triển nhằm mục tiêu cải thiện việc phân bổ pod bằng cách tích hợp các chỉ số nút (node metrics) theo thời gian thực và tôn trọng các ưu tiên affinity do pod định nghĩa.  

Báo cáo này trình bày chi tiết về kiến trúc và quy trình hoạt động của bộ lập lịch tùy chỉnh. Nội dung tập trung vào:

- Kiến trúc tổng quan: Mô tả các thành phần chính bao gồm ứng dụng scheduler tùy chỉnh (viết bằng Golang), sự tương tác với Kubernetes API Server, và việc tích hợp với Prometheus để thu thập chỉ số thời gian thực từ các Node Exporter chạy trên mỗi nút.   

- Quy trình lập lịch chi tiết: Đi sâu vào các giai đoạn của quá trình lập lịch, bao gồm cơ chế phát hiện và theo dõi pod cần lập lịch, giai đoạn lọc (Predicate) để chọn các nút tương thích dựa trên yêu cầu tài nguyên, taint/toleration, và node selector, giai đoạn tính điểm (Scoring) để ưu tiên các nút dựa trên bộ nhớ khả dụng, CPU rảnh (lấy từ Prometheus) và các quy tắc affinity, và cuối cùng là giai đoạn ràng buộc (Binding) để gán pod cho nút được chọn.  
- Cấu hình và triển khai: Hướng dẫn các khía cạnh cấu hình cần thiết, bao gồm định danh bộ lập lịch cho pod, Kiểm soát Truy cập Dựa trên Vai trò (RBAC), triển khai bộ lập lịch, thiết lập Prometheus và Node Exporter, cùng các ví dụ minh họa và kiểm thử.  
- Thực hành (Demo): Trình bày các bước cài đặt trên Google Kubernetes Engine (GKE) và so sánh hoạt động của bộ lập lịch tùy chỉnh với bộ lập lịch mặc định trong các kịch bản khác nhau như lập lịch dựa trên tài nguyên thực tế, node selector, taints/tolerations và node affinity.  

Mục tiêu của dự án là cung cấp một giải pháp lập lịch thông minh hơn, linh hoạt hơn, giúp tối ưu hóa việc sử dụng tài nguyên và nâng cao hiệu suất hoạt động của các ứng dụng trên Kubernetes.

#v(0.3cm)

*_Từ khóa:_* Kubernetes, Custom Kubernetes Scheduler, Bộ lập lịch Kubernetes, Cấp phát tài nguyên, Prometheus, Node Exporter, Node Affinity, Taints and Tolerations, Kubernetes Scheduling.

#pagebreak()
