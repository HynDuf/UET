#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Giới thiệu <chuong1>
]


#heading(level: 2, "Giới thiệu chung")


#heading(level: 3, "Sự phát triển của kiến trúc phần mềm")

Trong những giai đoạn đầu của công nghệ phần mềm, các ứng dụng thường được xây dựng theo mô hình monolithic (kiến trúc nguyên khối), nơi toàn bộ chức năng được tích hợp trong một chương trình duy nhất. Kiến trúc này đơn giản, phù hợp với các hệ thống nhỏ và đội ngũ phát triển hạn chế. Tuy nhiên, khi yêu cầu của người dùng ngày càng tăng và hệ thống ngày càng phức tạp, monolithic bộc lộ nhiều hạn chế:
- Tính độc lập cao dẫn đến hệ thống vô cùng kém linh hoạt, khó tích hợp, kết hợp với ứng dụng bên ngoài.

- Các thành phần phụ thuộc vào nhau, mức độ ràng buộc lớn, dẫn đến các tính năng khó phát triển độc lập, khó mở rộng và bảo trì phức tạp.
- Cập nhật một thành phần dù nhỏ vẫn phải build, deploy lại toàn bộ ứng dụng
- $dots$

Để đáp ứng nhu cầu phát triển nhanh chóng và mở rộng linh hoạt, kiến trúc phần mềm đã tiến hóa dần qua các mô hình như layered architecture (kiến trúc phân lớp), event-driven architecture (kiến trúc hướng sự kiện), và đặc biệt là microservices architecture (kiến trúc dịch vụ nhỏ). Các kiến trúc ngày càng cải thiện hệ thống để dễ dàng mở rộng theo nhu cầu, cho phép các đội nhóm phát triển và triển khai độc lập từng phần nhỏ của ứng dụng.

Trong kiến trúc microservices, ứng dụng được chia thành nhiều dịch vụ nhỏ, mỗi microservice chạy như một tiến trình độc lập và giao tiếp với các dịch vụ khác thông qua các giao diện (API) được xác định rõ ràng và đơn giản. Mỗi dịch vụ có thể được viết bằng ngôn ngữ phù hợp nhất để thực hiện nó, được coi là một ứng dụng con hoàn toàn độc lập, các thành phần khác bên ngoài chỉ gọi API, biết được đầu vào và đầu ra của ứng dụng Giao thức được sử dụng có thể là các giao thức đồng bộ như HTTP thông qua API RESTful, hoặc các giao thức không đồng bộ như AMQP (Advanced Message Queueing Protocol). Các giao thức này đơn giản, dễ hiểu đối với nhà phát triển và không bị ràng buộc với bất kỳ ngôn ngữ lập trình cụ thể nào. 

Mỗi microservice là một tiến trình độc lập với API ít thay đổi, theo đó có thể phát triển và triển khai chúng một cách độc lập. Thay đổi một microservice không yêu cầu cập nhật hoặc triển khai lại các microservice khác, với điều kiện API giữ nguyên. 

#figure(
  image("../images/chuong1/sw_archirtecture.png"),
  caption: [Kiến trúc Monolith và kiến trúc Microservices]
)

Với số lượng các dịch vụ cần được triển khai và các cơ sở hạ tầng dữ liệu, phần cứng ngày càng lớn, việc cấu hình, quản lý và duy trì hệ thống vận hành trơn tru là một thách thức lớn. Bài toán về việc phải deploy các thành phần của hệ thống ở những phần cứng nào sao cho tối ưu tài nguyên, tiết kiệm chi phí thậm chí là vô cùng khó giải, cần chuyên môn cao. Có thể nói, làm tất cả điều này một cách thủ công không hề dễ dàng. Ta kì vọng rằng ta có thể tự động hóa các công việc như lập lịch để các thành phần đi vào server, tự động cấu hình, giám sát và xử lí sự cố. Đây chính là những công việc mà Kubernetes sẽ giải quyết

#heading(level: 3, "Quy trình phát triển phần mềm và văn hóa DevOps")
Quy trình phát triển phần mềm là tập hợp các bước và phương pháp được tổ chức tuần tự hoặc linh hoạt nhằm thiết kế, xây dựng, kiểm thử và triển khai các sản phẩm phần mềm. Quy trình phát triển là yếu tố quan trọng đảm bảo sự thành công cửa dự án phần mềm, đảm bảo phần mềm được phát triển đúng yêu cầu, đạt chất lượng mong muốn và có khả năng bảo trì lâu dài.Cùng với sự phát triển của kiến trúc phần mềm, quy trình phát triển phần mềm cũng đã trải qua nhiều giai đoạn thay đổi nhằm đáp ứng yêu cầu tăng tốc độ phát hành sản phẩm, nâng cao chất lượng và đảm bảo khả năng thích ứng nhanh với biến động thị trường.


Ban đầu, các mô hình phát triển như Waterfall (mô hình thác nước) được áp dụng. Mô hình Waterfall chia quy trình phát triển thành các giai đoạn riêng biệt: phân tích yêu cầu, thiết kế, cài đặt, kiểm thử và triển khai. Các giai đoạn này được thực hiện tuần tự, chỉ chuyển sang bước tiếp theo khi hoàn thành bước trước. Tuy rất  bài bản, đơn giản, dễ hiểu, dễ quản lý; song mô hình Waterfall chỉ tỏ ra phù hợp với với những dự án nhỏ và có yêu cầu rõ ràng ngay từ đầu; mô hình này bộc lộ nhiều hạn chế trong môi trường thay đổi nhanh,  khó thích ứng nếu có thay đổi yêu cầu sau mỗi giai đoạn.

#figure(
  image("../images/chuong1/waterfall_model.png", height: 30%),
  caption: [Mô hình phát triển thác nước]
)

Sự xuất hiện của các phương pháp phát triển linh hoạt (Agile) đã giúp quy trình phát triển phần mềm trở nên linh động hơn. Agile tiếp cận phát triển phần mềm theo hướng lặp (iterations) và gia tăng (incremental). Sản phẩm được xây dựng qua nhiều chu kỳ ngắn, với sự phản hồi liên tục từ khách hàng và cải tiến liên tục. 

Trong các mô hình phát triển phần mềm truyền thống, sau khi các developers (nhà phát triển hoặc lập trình viên) hoàn thành việc lập trình, kiểm thử nội bộ và đóng gói phần mềm, sản phẩm sẽ được chuyển giao cho một bộ phận riêng biệt gọi là Operations Team (gọi tắt là Ops Team). Tuy nhiên, cách làm này cũng có một số vấn đề:
- Developers không hiểu hết môi trường production.
- Ops gặp khó khăn khi sản phẩm thiếu tài liệu hoặc chưa tối ưu.
- Quá trình bàn giao chậm, gây chậm trễ phát hành sản phẩm.


Trên nền tảng Agile, văn hóa DevOps ra đời nhằm hợp nhất phát triển phần mềm (Dev) và vận hành hệ thống (Ops). DevOps thúc đẩy việc tự động hóa các quy trình xây dựng (build), kiểm thử (test), triển khai (deploy) và giám sát (monitoring) phần mềm; từ đó Rút ngắn chu kỳ phát hành phần mềm, giảm thiểu lỗi trong quá trình triển khai, tăng tính ổn định và khả năng phục hồi của hệ thống, đồng thời tạo môi trường hợp tác chặt chẽ hơn giữa các nhóm dev và ops. Trong bối cảnh đó, các công nghệ như container, orchestration, và hệ thống tự động hóa hạ tầng trở thành những thành phần cốt lõi hỗ trợ hiện thực hóa văn hóa DevOps trong thực tiễn.
#figure(
  image("../images/chuong1/devops.png", width: 102%),
  caption: [Luồng phát triển với Devops và các công nghệ liên quan ]
)
#{
  heading(level: 2, "Container")
}
#heading(level: 3, "Sự nhất quán về môi trường phát triển")

Trong thực tế phát triển phần mềm, sự khác biệt giữa môi trường phát triển (Developement Environment), môi trường triển khai (Stage Environment) và môi trường sử dụng (Product Envidrronement) là hiện tượng thường xuyên xảy ra; sự khác biệt này có thể đến từ nhiều yếu tố: Phần cứng, Hệ điều hành và phiên bản, Các thư viện, phần mềm hỗ trợ và cấu hình hệ thống, $dots$). Đây là nguyên nhân gây ra nhiều khó khăn và tốn kém thời gian trong quá trình phát triển và vận hành sản phẩm.

Trong quy trình truyền thống, môi trường production (môi trường vận hành chính thức) thường được quản lý bởi nhóm Operations (Ops), trong khi các developers (nhà phát triển) tự thiết lập môi trường riêng của mình để phục vụ việc lập trình. Hai môi trường này không chỉ khác biệt về cấu hình kỹ thuật mà còn khác biệt về mức độ ưu tiên: các quản trị viên hệ thống chú trọng việc cập nhật bản vá bảo mật và tính ổn định lâu dài, trong khi nhà phát triển lại tập trung vào tốc độ triển khai và thử nghiệm các tính năng mới. 

Ngoài ra, môi trường của người sử dụng cuối — đặc biệt trong các ứng dụng phổ thông — còn biến động liên tục, chịu ảnh hưởng bởi thay đổi phần cứng, cập nhật hệ điều hành, hoặc thay đổi trình duyệt, nền tảng di động, v.v. Đây là yếu tố mà các nhà phát triển cần nghiên cứu kỹ và chuẩn bị phương án thích ứng linh hoạt.

Docker Container ra đời như một giải pháp hiệu quả để giải quyết bài toán về sự khác biệt môi trường giữa các giai đoạn phát triển, triển khai và vận hành. Docker tạo ra các container bằng cách đóng gói ứng dụng cùng với toàn bộ các thư viện, công cụ hỗ trợ và cấu hình cần thiết vào trong một đơn vị độc lập, nhẹ và di động. Nhờ container, ứng dụng có thể chạy ổn định trên bất kỳ môi trường nào có hỗ trợ công nghệ container, bất kể sự khác biệt về hệ điều hành, thư viện hệ thống hay phần cứng bên dưới.

#figure(
  image("../images/chuong1/docker_build.png", width: 85%),
  caption: [Cách docker chạy ứng dụng]
)

Bằng cách cô lập môi trường vận hành của ứng dụng trong một lớp ảo hóa nhẹ, container đảm bảo rằng "những gì chạy được trên máy của lập trình viên cũng sẽ chạy được trên server production". Điều này làm giảm đáng kể các lỗi do khác biệt môi trường, đồng thời đơn giản hóa quy trình phát triển, kiểm thử, triển khai và vận hành phần mềm.

#heading(level: 3, "Phân bổ tài nguyên")
Trong quá trình vận hành các hệ thống phần mềm, quản lý và phân bổ tài nguyên (bao gồm CPU, bộ nhớ RAM, băng thông mạng, và lưu trữ) là một vấn đề cốt lõi để đảm bảo hiệu suất và tính ổn định của dịch vụ. Ban đầu, các ứng dụng được chạy trên các máy chủ vật lý, chia sẻ tài nguyên chung của hệ thống. Không có cách nào để xác định ranh giới tài nguyên cho các ứng dụng trong máy chủ, điều này dẫn đến tình trạng phân bổ tài nguyên không đồng đều. 

Một cách giải quyết đơn giản cho vấn đề cô lập ứng dụng là chạy mỗi ứng dụng trên một máy chủ vật lý riêng biệt. Tuy nhiên, giải pháp này không tối ưu và bộc lộ nhiều hạn chế: tài nguyên trên mỗi máy chủ thường không được tận dụng hết (ví dụ CPU và bộ nhớ còn dư thừa), dẫn đến lãng phí tài nguyên. Đồng thời, việc duy trì một số lượng lớn máy chủ vật lý gây ra chi phí rất cao về cả phần cứng, không gian lưu trữ, điện năng và công tác vận hành cho các tổ chức.

Một giải pháp khác là sử dụng công nghệ ảo hóa. Ảo hóa cho phép một máy chủ vật lý vận hành đồng thời nhiều Máy ảo (Virtual Machine – VM), mỗi máy ảo như một hệ thống độc lập với hệ điều hành và tài nguyên riêng, hoạt động bên trên một lớp phần cứng được ảo hóa. Nhờ đó, các ứng dụng có thể tận dụng tốt hơn tài nguyên phần cứng của máy chủ vật lý, đồng thời cho phép khả năng mở rộng linh hoạt, khi việc bổ sung hoặc cập nhật ứng dụng chỉ cần triển khai thêm máy ảo mới mà không yêu cầu thêm phần cứng vật lý. Công nghệ ảo hóa đã góp phần giảm chi phí đầu tư hạ tầng, nâng cao hiệu quả sử dụng tài nguyên và cho phép tổ chức xây dựng các cụm máy ảo như một tập hợp tài nguyên sẵn sàng cho nhiều ứng dụng khác nhau.

Khi một ứng dụng chỉ bao gồm một số lượng nhỏ các thành phần lớn, việc cấp phát một Máy ảo (Virtual Machine – VM) riêng cho mỗi thành phần và cô lập môi trường bằng cách cung cấp hệ điều hành riêng cho từng VM là hoàn toàn khả thi và hợp lý. Tuy nhiên, khi các thành phần của ứng dụng trở nên nhỏ hơn, đồng thời số lượng thành phần tăng lên, việc tiếp tục sử dụng nhiều VM độc lập trở nên kém hiệu quả. Mỗi VM cần vận hành một hệ điều hành riêng, chiếm dụng thêm bộ nhớ, tài nguyên CPU và dung lượng lưu trữ, dẫn đến lãng phí tài nguyên vật lý. Bên cạnh đó, việc mỗi VM yêu cầu quá trình cấu hình, cập nhật và quản lý riêng biệt cũng làm tăng đáng kể khối lượng công việc vận hành. Khi số lượng VM ngày càng lớn, tổ chức phải đầu tư thêm nguồn nhân lực cho việc quản trị hệ thống, gây tốn kém chi phí và làm giảm hiệu quả vận hành tổng thể.

#figure(
  image("../images/chuong1/vm_container.png"),
  caption: [Kiến trúc Virtual Machine và Container]
)

Sự xuất hiện của công nghệ Container đã thay đổi căn bản cách thức quản lý tài nguyên. Container cho phép chúng ta chạy nhiều dịch vụ khác nhau trên cùng một máy chủ vật lý, đồng thời vẫn đảm bảo mỗi dịch vụ có môi trường vận hành riêng biệt, cho phép giới hạn tài nguyên và được cô lập an toàn với các dịch vụ khác, tương tự như cách Máy ảo (VM) thực hiện. Tuy nhiên, khác với VM, container không cần hệ điều hành riêng cho mỗi đơn vị, do đó yêu cầu ít tài nguyên hơn rất nhiều, chúng ta cũng không cần khởi động toàn bộ hệ điều hành như khi khởi động một VM, việc khởi chạy container cũng nhanh hơn đáng kể. Một tiến trình trong container có thể khởi chạy ngay lập tức, giúp tăng tốc độ triển khai ứng dụng và tối ưu hoá hiệu suất sử dụng tài nguyên.

#heading(level: 3, "Container")

Container là một công nghệ cung cấp phương thức đóng gói ứng dụng cùng với toàn bộ các thư viện, công cụ, và thiết lập môi trường cần thiết, đảm bảo rằng ứng dụng có thể chạy nhất quán và ổn định trên bất kỳ nền tảng nào hỗ trợ nó.

Khái niệm container hóa không phải là mới, mà đã được nghiên cứu từ những năm 1970 với các công nghệ như chroot trên Unix, cho phép cô lập hệ thống file cho một tiến trình. Sau đó, các bước tiến lớn hơn được thực hiện đưa việc cô lập tiến trình và tài nguyên lên một tầm cao mới. Đến năm 2013, công cụ Docker ra đời và đã làm cho container trở nên phổ biến nhờ việc đơn giản hóa quá trình đóng gói, phân phối và vận hành các container, mở đường cho sự bùng nổ của container trong các hệ thống phần mềm hiện đại.

Khác với Máy ảo (Virtual Machine – VM), mỗi container không cần vận hành hệ điều hành riêng biệt. Thay vào đó, các tiến trình trong container chạy trực tiếp trên hệ điều hành của máy chủ vật lý, tương tự như các tiến trình thông thường, nhưng được cô lập với các tiến trình khác nhờ các cơ chế của hệ điều hành. Đối với mỗi tiến trình bên trong container, nó nhận thức như thể mình đang vận hành trên một hệ thống riêng biệt, với hệ điều hành và tài nguyên độc lập. Điều này giúp container nhẹ hơn, tiêu tốn ít tài nguyên hơn và có khả năng khởi động gần như tức thì, mang lại lợi thế lớn về tốc độ triển khai và hiệu quả sử dụng hạ tầng.

Một trong những cơ chế quan trọng đảm bảo sự cô lập và quản lý tài nguyên trong container là sự kết hợp giữa cgroups (control groups) và namespaces, hai tính năng cốt lõi của nhân (kernel) Linux. Cgroups cho phép giới hạn lượng tài nguyên hệ thống mà một container có thể tiêu thụ, bao gồm CPU, bộ nhớ RAM, băng thông mạng, và các tài nguyên khác. Namespaces đảm bảo rằng mỗi container có không gian riêng biệt về tiến trình, mạng, hệ thống tập tin và các tài nguyên khác, khiến các tiến trình bên trong container chỉ "nhìn thấy" những tài nguyên được cấp cho container đó. Nhờ sự kết hợp này, các container không thể chiếm dụng tài nguyên vượt mức cấu hình, và tiến trình trong container này cũng không thể làm ảnh hưởng đến tiến trình trong container khác, tương tự như khi chúng chạy trên các máy chủ vật lý riêng biệt. 

#heading(level: 3, "Docker")
Mặc dù công nghệ container đã xuất hiện từ khá lâu, nhưng chỉ đến khi nền tảng Docker ra đời, container mới thực sự trở nên phổ biến và được tiếp cận rộng rãi. Docker là hệ thống container đầu tiên cung cấp khả năng di chuyển container dễ dàng giữa các máy chủ khác nhau mà không cần phải lo lắng về sự khác biệt môi trường. Docker đã đơn giản hóa toàn bộ quy trình đóng gói ứng dụng, không chỉ bao gồm mã nguồn, thư viện và các phụ thuộc cần thiết, mà còn cả hệ thống tệp của môi trường vận hành, thành một gói di động thống nhất. Gói này, gọi là Docker Image, có thể được triển khai trên bất kỳ máy chủ nào có cài đặt Docker, bất kể nền tảng phần cứng hoặc hệ điều hành bên dưới.

Điểm mạnh lớn nhất của Docker là khả năng cô lập hoàn toàn môi trường vận hành cho ứng dụng. Khi một ứng dụng chạy bên trong Docker container, tiến trình chỉ nhìn thấy các thư viện, module và cấu hình được đóng gói bên trong container, hoàn toàn tách biệt với môi trường hệ điều hành bên ngoài. Nhờ đó, lập trình viên và tổ chức không còn phải lo lắng về việc ứng dụng có thể hoạt động khác nhau ở các môi trường phát triển, kiểm thử hay triển khai thực tế. Chỉ cần đóng gói ứng dụng vào một Docker container, chúng ta có thể mang nó đến bất cứ đâu và chạy ổn định mà không cần thiết lập lại môi trường.

#figure(
  image("../images/chuong1/docker.png", height: 31%),
  caption: [Docker]
)

Một điểm khác biệt quan trọng giữa Docker Image và image của máy ảo (VM Image) là cách thức tổ chức theo cấu trúc lớp (layered architecture). Mỗi Docker Image được xây dựng từ nhiều lớp chồng lên nhau, và các lớp này có thể được chia sẻ hoặc tái sử dụng giữa các images khác nhau. Điều đó có nghĩa là khi triển khai một Docker Image mới, nếu máy chủ đã có sẵn một số lớp chung từ trước, chỉ những lớp mới cần tải xuống, giúp tiết kiệm đáng kể băng thông, thời gian và không gian lưu trữ.

#{
  heading(level: 2, "Điều phối container")
}

Khi số lượng thành phần ứng dụng trong hệ thống ngày càng tăng, việc quản lý và triển khai tất cả các thành phần đó trở nên ngày càng phức tạp. Google là một trong những công ty đầu tiên nhận ra nhu cầu cấp thiết về một phương pháp tốt hơn để triển khai và vận hành phần mềm cũng như cơ sở hạ tầng ở quy mô toàn cầu. Với việc vận hành hàng trăm nghìn máy chủ trên khắp thế giới, Google đã phải đối mặt với những thách thức lớn trong việc quản lý hệ thống phân tán quy mô siêu lớn. Điều này đã thúc đẩy họ phát triển những giải pháp nội bộ nhằm tự động hóa và tối ưu hóa quá trình phát triển, triển khai và vận hành hàng nghìn thành phần phần mềm, đồng thời đảm bảo khả năng quản lý hiệu quả và kiểm soát chi phí ở quy mô chưa từng có.

#heading(level: 3, "Hệ thống điều phối container")

Để giải quyết những thách thức trong việc vận hành một hệ thống khổng lồ gồm hàng trăm nghìn máy chủ, Google đã phát triển một hệ thống nội bộ có tên là Borg (sau này thay thế bởi Omega). Borg là nền tảng điều phối container quy mô lớn, được thiết kế để tự động hóa việc triển khai, quản lý và giám sát các ứng dụng chạy trên hạ tầng phân tán toàn cầu của Google.

Sau gần một thập kỷ vận hành nội bộ các hệ thống như Borg và Omega, vào năm 2014, Google đã quyết định chia sẻ kinh nghiệm của mình với cộng đồng bằng cách ra mắt Kubernetes – một nền tảng mã nguồn mở được xây dựng dựa trên những bài học thực tiễn thu thập từ việc vận hành các hệ thống quy mô lớn. Kubernetes kế thừa nhiều nguyên lý thiết kế và mô hình vận hành từ Borg, Omega cùng các hệ thống nội bộ khác của Google, nhưng được đơn giản hóa để phù hợp với nhu cầu triển khai container trong cộng đồng rộng lớn hơn.

#heading(level: 3, "Kubernetes")

Kubernetes là một hệ thống phần mềm mã nguồn mở giúp tự động hóa việc triển khai, quản lý và mở rộng các ứng dụng container trên hệ thống máy chủ. Dựa trên các tính năng cô lập và quản lý tài nguyên của container của Linux, Kubernetes cho phép vận hành các ứng dụng mà không cần can thiệp sâu vào chi tiết nội bộ của từng ứng dụng, cũng như không cần triển khai thủ công lên từng máy chủ riêng lẻ.

Kubernetes cho phép vận hành các ứng dụng phần mềm trên hàng nghìn máy chủ (node) như thể chúng là một khối tài nguyên duy nhất. Bằng cách trừu tượng hóa toàn bộ hạ tầng phần cứng, Kubernetes biến cả trung tâm dữ liệu thành một "máy tính khổng lồ", nơi các nhà phát triển chỉ cần triển khai thành phần ứng dụng mà không cần biết chi tiết máy chủ vật lý nào sẽ đảm nhận công việc đó. Khi triển khai một ứng dụng có nhiều thành phần, Kubernetes tự động chọn máy chủ phù hợp cho từng thành phần, triển khai chúng, đồng thời thiết lập khả năng kết nối, giao tiếp dễ dàng giữa các thành phần trong toàn bộ hệ thống.

Một trong những đặc điểm nổi bật của Kubernetes là quy trình triển khai ứng dụng luôn nhất quán, bất kể quy mô của cụm (cluster). Cho dù cụm chỉ bao gồm vài nút hay hàng nghìn nút máy chủ, cách thức triển khai và vận hành ứng dụng vẫn hoàn toàn không thay đổi. Khi mở rộng quy mô cụm bằng cách bổ sung thêm các nút mới, Kubernetes đơn giản coi đây là sự gia tăng về tài nguyên tính toán khả dụng. Các tài nguyên mới sẽ tự động được tích hợp vào cụm, sẵn sàng để các ứng dụng đã triển khai sử dụng mà không cần thay đổi quy trình phát triển hay triển khai của người dùng.

Quay trở lại với vấn đề quy trình phát triển phần mềm, Kubernetes ra đời đã mở ra một cách tiếp cận mới, cho phép các nhà phát triển (developers) tự triển khai ứng dụng của họ và thực hiện các lần triển khai thường xuyên theo nhu cầu, mà không cần sự hỗ trợ trực tiếp từ đội ngũ vận hành (operations).
Không chỉ mang lại lợi ích cho các nhà phát triển, Kubernetes còn hỗ trợ đội ngũ vận hành bằng cách tự động giám sát, phát hiện lỗi phần cứng, và lên lịch lại ứng dụng một cách tự động khi có sự cố xảy ra. Vai trò của các quản trị viên hệ thống (sysadmins) cũng dần dịch chuyển: thay vì giám sát chi tiết từng ứng dụng riêng lẻ, họ tập trung chủ yếu vào việc giám sát và quản lý Kubernetes cũng như cơ sở hạ tầng tổng thể, trong khi Kubernetes tự động đảm nhiệm phần vận hành ứng dụng.

Nói một cách đơn giản, Kubernetes giúp đội ngũ phát triển và vận hành tập trung hơn vào công việc phát triển sản phẩm và cải tiến dịch vụ, trong khi các vấn đề về hạ tầng phần cứng và việc vận hành ứng dụng thường ngày đã được hệ thống tự động hóa và tối ưu hóa.

#heading(level: 3, "Các hệ thống điều phối container khác")

Ngoài Kubernetes — nền tảng phổ biến nhất hiện nay, còn có nhiều hệ thống điều phối khác như Docker Swarm, Apache Mesos với Marathon, Nomad của HashiCorp, và OpenShift. Mỗi hệ thống có những ưu điểm riêng, từ thiết kế đơn giản dễ sử dụng (Docker Swarm, Nomad) đến khả năng mở rộng mạnh mẽ cho hệ thống quy mô lớn (Kubernetes, Mesos).

#figure(
  image("../images/chuong1/container_orchestration.png"),
  caption: [Các hệ thống điều phối container phổ biến]
)

Các nền tảng này đều hướng tới mục tiêu chung là tối ưu hóa việc sử dụng tài nguyên hạ tầng, đảm bảo tính sẵn sàng cao cho ứng dụng, và giảm tải công việc vận hành thủ công cho các đội ngũ phát triển và quản trị hệ thống.

Trong khuôn khổ của bài báo cáo này, chúng tôi không đi sâu so sánh hoặc mô tả chi tiết về các hệ thống điều phối container khác ngoài Kubernetes. Các nội dung tiếp theo sẽ tập trung vào việc tìm hiểu và phân tích Kubernetes như một đại diện tiêu biểu cho mô hình điều phối container hiện đại.

#{
  heading(level: 2, "Kubernetes")
}

#heading(level: 3, "Cơ bản về Kubernetes")
Kubernetes có thể được hình dung như một hệ điều hành cho toàn bộ cụm máy chủ. Thay vì yêu cầu các nhà phát triển phải tích hợp thủ công các dịch vụ cơ sở hạ tầng vào ứng dụng, Kubernetes cung cấp sẵn các dịch vụ như khám phá dịch vụ (service discovery), mở rộng quy mô tự động (autoscaling), cân bằng tải (load balancing), tự phục hồi (self-healing), $dots$ Nhờ vậy, các nhà phát triển có thể tập trung hoàn toàn vào phát triển tính năng ứng dụng, thay vì tiêu tốn thời gian xử lý các vấn đề hạ tầng phức tạp.

Một hệ thống Kubernetes bao gồm một nút master (hoặc control plane) và một hoặc nhiều nút worker. Khi nhà phát triển gửi danh sách các ứng dụng cần triển khai tới nút master, Kubernetes tự động phân phối các ứng dụng này đến các nút worker trong cụm. Việc một thành phần ứng dụng chạy trên nút nào là chi tiết mà cả nhà phát triển lẫn quản trị viên hệ thống không cần quan tâm — Kubernetes tự động tối ưu hóa quá trình phân phối đó.

#figure(
  image("../images/chuong1/cluster.svg", width: 70%),
  caption: [Hệ thống Kubernetes]
)

Về bản chất, Kubernetes sẽ quyết định vị trí chạy các container ứng dụng một cách tự động, cung cấp cho các thành phần ứng dụng thông tin cần thiết để tìm thấy nhau và duy trì trạng thái hoạt động ổn định. Việc ứng dụng không phụ thuộc vào vị trí vật lý trên cụm cho phép Kubernetes di chuyển container linh hoạt khi cần thiết, từ đó cải thiện đáng kể mức độ sử dụng tài nguyên so với phương pháp lập lịch thủ công truyền thống.

Khi cần thiết, nhà phát triển có thể yêu cầu Kubernetes triển khai một số ứng dụng được chỉ định trên cùng một nút worker. Nhưng dù các thành phần ứng dụng nằm trên cùng nút hay khác nút, Kubernetes đảm bảo rằng chúng luôn có thể liên lạc với nhau một cách ổn định nhờ hệ thống mạng tích hợp.


#heading(level: 3, "Kiến trúc Kubernetes")

Kubernetes Cluster được thiết kế theo mô hình client-server, với các thành phần đảm nhiệm những vai trò riêng biệt nhằm cung cấp một môi trường quản lý ứng dụng container hóa hiệu quả. Thiết kế này hướng tới mục tiêu đảm bảo tính mở rộng (scalability), tính khả dụng cao (high availability) và tự động hóa trong triển khai, vận hành các ứng dụng.

Về tổng thể, kiến trúc của một Kubernetes Cluster bao gồm hai thành phần chính:

- Master Node: Lưu trữ Kubernetes Control Plane, quản lý trạng thái chung của cụm, chịu trách nhiệm điều phối (orchestration), lập lịch (scheduling) và giám sát toàn bộ hệ thống. 
- Worker Node: Thực thi các container ứng dụng thực tế, nhận lệnh từ Control Plane và đảm bảo vận hành các workload theo yêu cầu.

#figure(
  image("../images/chuong1/archirtecture.svg"),
  caption: [Kiến trúc Kubernetes]
)


#heading(level: 4, "Control Plane")
Control Plane là bộ phận chịu trách nhiệm điều khiển và quản lý toàn bộ Kubernetes Cluster, đảm bảo rằng cụm hoạt động ổn định và đúng theo trạng thái mong muốn. Control Plane điều phối việc triển khai container, giám sát trạng thái các thành phần, và phản ứng tự động khi có thay đổi trong hệ thống.

Các thành phần của Control Plane có thể được triển khai tập trung trên một nút master duy nhất, hoặc phân tán trên nhiều nút khác nhau để tăng tính sẵn sàng cao (high availability) và khả năng chịu lỗi.

Các thành phần chính trong Control Plane bao gồm:
- kube-apiserver: Thành phần trung tâm, cung cấp giao diện API để các thành phần khác tương tác và quản lý cluster.
- kube-scheduler: Chịu trách nhiệm lập lịch, quyết định node nào sẽ chạy các pod mới dựa trên tài nguyên khả dụng và chính sách đã thiết lập.
- kube-controller-manager: Thực hiện các chức năng ở cấp độ cụm, chẳng hạn như sao chép các thành phần, theo dõi các nút worker, xử lý lỗi nút. 
- etcd: Hệ thống lưu trữ key-value phân tán, lưu trữ toàn bộ trạng thái cấu hình và dữ liệu của cluster.
- cloud-controller-manager (nếu sử dụng môi trường cloud): Quản lý tương tác giữa Kubernetes và các dịch vụ của nhà cung cấp cloud như load balancer, volume lưu trữ,...

Mặc dù các thành phần của Control Plane chịu trách nhiệm nắm giữ và điều khiển trạng thái tổng thể của cụm, chúng không trực tiếp thực thi các ứng dụng mà người dùng triển khai. Việc chạy các container ứng dụng thực tế được giao cho các nút worker (worker nodes).

#heading(level: 4, "Node")
Node là nơi thực thi các container ứng dụng trong một Kubernetes Cluster. Mỗi node là một máy worker có nhiệm vụ nhận chỉ thị từ Control Plane, khởi chạy và quản lý các container, theo dõi tài nguyên cục bộ, và đảm bảo các ứng dụng luôn vận hành ổn định.


#figure(
  image("../images/chuong1/nodes.svg"),
  caption: [Node]
)

Các chức năng này được thực hiện thông qua các thành phần chính sau đây trên mỗi node:

- Container Runtime: Công cụ chạy các container (ví dụ: containerd, CRI-O, hoặc Docker).
- kubelet: Thành phần chịu trách nhiệm giao tiếp với Control Plane, nhận lệnh và quản lý các container trên node đó.
- kube-proxy: Quản lý mạng nội bộ, định tuyến lưu lượng đến đúng container, hỗ trợ cân bằng tải mạng.

#heading(level: 3, "Một số thành phần cơ bản của Kubernetes")

#figure(
  image("/images/chuong1/components-of-kubernetes.svg"),
  caption: [Các thành phần của Kubernetes]
)

#heading(level: 4, "Pod")
Một Pod trong Kubernetes là nhóm gồm một hoặc nhiều container được triển khai cùng nhau, chia sẻ tài nguyên lưu trữ, tài nguyên mạng và một cấu hình chung xác định cách thức vận hành các container bên trong. Trong Kubernetes, Pod là đơn vị nhỏ nhất được triển khai và lập lịch. Khi người dùng gửi yêu cầu tạo ứng dụng, Kubernetes sinh ra các đối tượng Pod, và trình lập lịch (scheduler) sẽ quyết định vị trí triển khai Pod trong cụm.

Trong thực tế, một Pod thường chỉ chứa một container duy nhất. Tuy nhiên, khi một Pod chứa nhiều container, tất cả các container đó luôn chạy trên cùng một nút worker, chia sẻ cùng địa chỉ IP và không gian lưu trữ, và được quản lý như một khối thống nhất.

#figure(
  image("../images/chuong1/pods.svg", width: 85%),
  caption: [Pod trong Kubernetes]
)


Khái niệm Pod có thể được liên tưởng đến môi trường truyền thống, nơi các ứng dụng liên quan thường chạy chung trên cùng một máy vật lý hoặc máy ảo. Trong môi trường đám mây, Kubernetes sử dụng Pod để gom nhóm các container ứng dụng có liên quan vào một đơn vị logic, giúp tối ưu hóa khả năng vận hành, phối hợp và chia sẻ tài nguyên giữa các thành phần bên trong hệ thống.

// #heading(level: 5, numbering: none, "Giao tiếp mạng trong Kubernetes")
// Trong Kubernetes, tất cả các container bên trong cùng một Pod chia sẻ chung các namespace mạng (Network Namespace) và UTS namespace (Unix Timesharing System Namespace) của Linux. Điều này có nghĩa là:

// - Các container trong một Pod sử dụng cùng một tên máy chủ (hostname),
// - Chia sẻ cùng một giao diện mạng,
// - Có cùng một địa chỉ IP và không gian cổng.

// Tương tự, các container trong một Pod cũng dùng chung IPC namespace (Inter-Process Communication Namespace), cho phép chúng giao tiếp trực tiếp thông qua các cơ chế IPC như shared memory hoặc semaphores.

// Vì các container cùng Pod chia sẻ địa chỉ IP và không gian cổng, các tiến trình bên trong chúng cần lưu ý không trùng số cổng khi thiết lập dịch vụ mạng, để tránh gây xung đột. Tuy nhiên, xung đột cổng chỉ có thể xảy ra giữa các container trong cùng một Pod; còn các container thuộc các Pod khác nhau sẽ không bị ảnh hưởng, bởi mỗi Pod có không gian địa chỉ mạng và vùng cổng riêng biệt.

// Bên cạnh đó, trong một cụm Kubernetes, tất cả các Pod nằm trong một không gian địa chỉ mạng phẳng và duy nhất. Điều này có nghĩa là mỗi Pod được cấp phát một địa chỉ IP riêng biệt để các Pod có thể giao tiếp trực tiếp với nhau bằng địa chỉ IP, không cần NAT (Network Address Translation). Giao tiếp giữa các Pod tương tự như các máy tính trong cùng một mạng LAN, bất kể chúng được triển khai trên cùng một nút worker hay trên các nút khác nhau trong cụm.

// Nhờ thiết kế mạng phẳng này, khi một Pod gửi gói tin đến một Pod khác, địa chỉ IP nguồn trong gói tin chính là địa chỉ IP thực của Pod gửi. Điều này giúp việc phát triển và vận hành hệ thống trở nên đơn giản hơn, vì các ứng dụng có thể giao tiếp với nhau qua IP trực tiếp mà không cần phải xử lý phức tạp các vấn đề chuyển đổi địa chỉ.

// #heading(level: 4, "Service")
// #heading(level: 4, "Volume")
// #heading(level: 4, "ConfigMap")
// #heading(level: 4, "Deployment")


#heading(level: 4, "Kubelet")
Kubelet là một thành phần cốt lõi trong hệ thống Kubernetes, chạy trên mỗi worker node. Vai trò chính của kubelet là đảm bảo rằng các container ứng dụng trong các Pod được khởi chạy và duy trì trạng thái đúng với yêu cầu đã khai báo trong cluster.

Khi một Pod đã được trình lập lịch gán vào một node cụ thể, kubelet trên node đó sẽ:

- Theo dõi trạng thái các Pod được phân công cho mình bằng cách liên tục truy vấn thông tin,
- Kéo (pull) các container image cần thiết từ Registry,
- Tạo và quản lý container bằng cách sử dụng hệ thống Container Runtime cục bộ (ví dụ như containerd, CRI-O hoặc Docker),
- Giám sát sức khỏe (health check) và trạng thái hoạt động của các container (liveness, readiness),
- Báo cáo trạng thái Pod và container để cập nhật vào trạng thái chung của cluster.

Ngoài ra, kubelet còn chịu trách nhiệm:
- Quản lý PodSpec (cấu hình mô tả Pod) cục bộ,
- Đảm bảo rằng nếu một container thất bại (crash hoặc unhealthy), nó sẽ tự động khởi động lại theo chính sách khôi phục được khai báo (restartPolicy),
- Xử lý việc gắn kết các thành phần bộ nhớ lưu trữ theo yêu cầu của Pod.

Về cơ bản, kubelet đóng vai trò như "quản gia" của mỗi node worker: tiếp nhận mệnh lệnh triển khai từ Control Plane và đảm bảo rằng tài nguyên ứng dụng trên node đó vận hành đúng yêu cầu mong đợi. 

Một điểm quan trọng cần lưu ý là kubelet chỉ quản lý các container được tạo ra bởi Kubernetes, không quản lý các container được khởi tạo thủ công bên ngoài hệ thống Kubernetes (ví dụ: container do người dùng tự tạo bằng lệnh docker run trực tiếp trên node). Điều này đảm bảo rằng kubelet chỉ chịu trách nhiệm đối với các workload do Kubernetes kiểm soát, từ đó duy trì tính nhất quán và độ tin cậy của cụm.

#heading(level: 4, "Kube API Server")
Kube API Server cung cấp giao diện lập trình (API) chính thức và là cổng giao tiếp duy nhất giữa các thành phần bên trong cluster cũng như giữa người dùng với hệ thống Kubernetes. Do đó, Kube API Server đóng vai trò như trung tâm điều phối thông tin giữa các thành phần.

Mọi yêu cầu từ người dùng, các công cụ quản lý (như kubectl, dashboard), hoặc các thành phần nội bộ (như scheduler, controller) đều phải đi qua API Server. Do đó, Kube API Server thực hiện các chức năng chính sau:

- Xử lý và xác thực các yêu cầu (requests): Kube API Server tiếp nhận tất cả các yêu cầu (REST API calls) và thực hiện các bước xác thực (authentication), phân quyền truy cập (authorization), và xác minh hợp lệ yêu cầu (admission control).

- Truy cập và cập nhật trạng thái cluster: Kube API Server là cầu nối giữa người dùng và cơ sở dữ liệu etcd. Khi có thay đổi đối tượng (Pod, Node, Deployment, ConfigMap...), API Server ghi nhận thay đổi đó vào etcd, đồng thời cung cấp trạng thái cluster cho các thành phần khác khi có yêu cầu.

- Cung cấp cơ chế Watch: Ngoài việc trả lời các yêu cầu đọc/ghi, Kube API Server hỗ trợ cơ chế watch: các thành phần như trình lập lịch (scheduler) hoặc trình quản lý điều khiển (Controller Manager) có thể đăng ký theo dõi các thay đổi tài nguyên, và nhận thông báo (notifications) khi có sự kiện mới (ví dụ Pod mới được tạo ra, Node bị lỗi).

- Đảm bảo tính nhất quán và khả năng mở rộng: Để hỗ trợ các cluster có quy mô lớn, Kube API Server được thiết kế để có thể triển khai nhiều instance (replica) đồng thời phía sau một load balancer. Các instance này đều truy cập etcd chung, đảm bảo tính nhất quán (consistency) và khả năng mở rộng (scalability) cho Control Plane.

#heading(level: 4, "etcd")
etcd là một hệ thống lưu trữ dữ liệu dạng key-value phân tán được Kubernetes sử dụng để duy trì toàn bộ trạng thái của cluster. Đây là thành phần đóng vai trò bộ nhớ trung tâm cho Control Plane, đảm bảo rằng mọi thay đổi đối với các tài nguyên (như Pod, Node, Service, ConfigMap, Secret, v.v.) đều được ghi nhận một cách nhất quán và có thể phục hồi.

Với vị trí là nguồn dữ liệu duy nhất về trạng thái hệ thống, etcd đóng vai trò thiết yếu trong việc duy trì tính đồng bộ và khả năng phục hồi cho toàn bộ cụm Kubernetes.

#heading(level: 4, "Scheduler")
Trình lập lịch (Kube Scheduler) là thành phần của Control Plane chịu trách nhiệm lập lịch (scheduling) — tức là quyết định Pod mới sẽ được chạy trên node nào trong cụm Kubernetes. Kube Scheduler giúp đảm bảo rằng workload được phân bổ hợp lý giữa các node, đáp ứng các yêu cầu về tài nguyên, hiệu năng, ràng buộc logic và chính sách vận hành.

Khi một Pod mới được tạo ra, nó sẽ chưa được gán node. TRình lập lịch sẽ phát hiện Pod này thông qua cơ chế watch của Kube API Server, sau đó thực hiện quy trình lập lịch gồm 3 bước chính
- Thực hiện quá trình lọc node (filtering), loại bỏ các node không đáp ứng yêu cầu (Không đủ CPU/RAM theo yêu cầu, Node nằm trong danh sách loại trừ của Pod, $dots$)
- Từ danh sách node khả thi, scheduler gán điểm số cho từng node theo các tiêu chí ưu tiên; lựa chọn node có điểm số cao nhất để gán cho Pod,
- Gửi yêu cầu binding thông qua API Server, sau đó kubelet trên node được chỉ định sẽ tiếp nhận Pod và thực thi

Kube Scheduler được thiết kế theo kiến trúc plugin, hỗ trợ tùy chỉnh toàn bộ quy trình lập lịch và hỗ trợ việc triển khai nhiều scheduler khác nhau cùng lúc trong một cụm. Kubernetes cung cấp nhiều plugin mặc định (như NodeResourcesFit, TaintToleration, NodeAffinity, InterPodAffinity...), người dùng có thể:
- Bật/tắt plugin,
- Cấu hình trọng số ưu tiên,
- Viết plugin mới bằng Go để mở rộng logic scheduling,
- Hoặc xây dựng trình lập lịch tùy chỉnh (custom scheduler) hoạt động song song với Kube Scheduler mặc định.

#heading(level: 3, "Luồng hoạt động của Kubernetes")
Để triển khai một ứng dụng trong Kubernetes, bước đầu tiên là đóng gói ứng dụng thành một hoặc nhiều container image. Các image này sau đó được đẩy lên một image registry (như Docker Hub, Google Container Registry, hoặc registry nội bộ), để các node trong cụm có thể truy xuất khi cần triển khai.

Tiếp theo, người dùng gửi một mô tả chi tiết về ứng dụng đến Kubernetes API Server. Mô tả này thường được viết dưới dạng tệp YAML hoặc JSON, bao gồm:

- Thông tin về image container cho từng thành phần của ứng dụng,
- Mối quan hệ giữa các thành phần, yêu cầu về việc đồng vị trí (ví dụ: nhiều container cần chạy trong cùng một Pod),
- Số lượng bản sao (replica) cần triển khai cho mỗi thành phần,
- Các đối tượng dịch vụ (Service) cần tạo để expose ứng dụng nội bộ hoặc ra bên ngoài thông qua một địa chỉ IP ổn định,
- Các chỉ dẫn về phân phối tài nguyên, gán node, chính sách restart, liveness/readiness probe,...

#heading(level: 5, numbering: none, "Luồng khởi động ứng dụng")

Khi API Server tiếp nhận mô tả ứng dụng, Kubernetes thực hiện các bước sau:

+ Scheduler xác định vị trí triển khai:
  - Scheduler theo dõi các Pod mới chưa được gán node và đánh giá các node khả dụng dựa trên tài nguyên hiện có (CPU, RAM, v.v.), chính sách ràng buộc và ưu tiên.
  - Scheduler chọn node phù hợp và gán Pod đó thông qua Kube API Server.
+ Kubelet triển khai container:
  - Kubelet trên mỗi node được giao Pod sẽ nhận thông tin qua API Server, sau đó tương tác với Container Runtime (như containerd hoặc Docker) để kéo image từ registry và khởi chạy các container theo cấu hình đã khai báo.

Ví dụ: Nếu một Pod chứa hai container (ví dụ: ứng dụng chính và container sidecar), thì cả hai sẽ được khởi chạy trên cùng một node, chia sẻ không gian mạng và tài nguyên lưu trữ.

#figure(
  image("../images/chuong1/pod_flow.png", width: 75%),
  caption: [Luồng khởi tạo của Pod]
)

Khi có nhiều bản sao của một Pod được yêu cầu (thông qua một đối tượng như Deployment), Kubernetes sẽ tự động lên lịch chúng trên các node khác nhau trong cluster để tối ưu hoá tài nguyên và tăng khả năng chịu lỗi.

#heading(level: 5, numbering: none, "Duy trì trạng thái ứng dụng")

Sau khi ứng dụng được triển khai, Kubernetes liên tục theo dõi và đảm bảo rằng trạng thái thực tế của hệ thống khớp với trạng thái mô tả mong muốn. Ví dụ:

- Nếu được yêu cầu duy trì 5 bản sao của một Pod, Kubernetes sẽ tự động tạo lại bản sao nếu một Pod bị lỗi, bị dừng hoặc không phản hồi.

- Nếu một node gặp sự cố (mất kết nối, lỗi phần cứng), các Pod đang chạy trên node đó sẽ được tự động lên lịch lại trên các node khác còn khả dụng.

Các probe như liveness và readiness được sử dụng để theo dõi sức khỏe container và quyết định khi nào cần khởi động lại hoặc loại bỏ container không ổn định.

#heading(level: 5, numbering: none, "Mở rộng quy mô ứng dụng")

Khi ứng dụng đang chạy, người vận hành có thể thay đổi số lượng bản sao (replica) bất kỳ lúc nào thông qua API Server. Kubernetes sẽ tự động tạo thêm hoặc huỷ bỏ Pod để kh ớp với số lượng mong muốn. Ngoài việc mở rộng thủ công, Kubernetes cũng hỗ trợ tự động điều chỉnh số lượng bản sao dựa trên các chỉ số thời gian thực như:

- Mức sử dụng CPU hoặc bộ nhớ,
- Số lượng yêu cầu mỗi giây,
- Hoặc bất kỳ chỉ số tùy chỉnh nào khác được ứng dụng cung cấp thông qua hệ thống giám sát.

Cơ chế này được gọi là Horizontal Pod Autoscaler (HPA), giúp đảm bảo ứng dụng có thể mở rộng linh hoạt theo nhu cầu sử dụng thực tế.

#heading(level: 4, "Lợi ích của việc sử dụng Kubernetes")

Dựa trên kiến trúc thiết kế và các tính năng vận hành, Kubernetes mang lại nhiều lợi ích thiết thực khi được áp dụng vào triển khai thực tế. Phần dưới đây sẽ tổng hợp và phân tích những giá trị cốt lõi mà Kubernetes đem lại trong quá trình vận hành hệ thống.

#figure(
  image("../images/chuong1/benefit_kubernetes.png", height: 35%),
  caption: [Lợi ích của việc sử dụng Kubernetes]
)

#heading(level: 5, numbering: none, "Đơn giản hóa triển khai ứng dụng")
Khi một cụm Kubernetes đã được thiết lập trên toàn bộ hạ tầng máy chủ, nhóm vận hành không còn cần can thiệp thủ công vào quá trình triển khai ứng dụng. Nhờ đặc tính tự chứa của container (bao gồm mã nguồn, thư viện và môi trường thực thi), việc cài đặt thủ công trên từng máy chủ trở nên không cần thiết. Ứng dụng có thể được triển khai tự động trên bất kỳ node nào trong cụm chỉ với một bản mô tả YAML mà không đòi hỏi sự trợ giúp từ quản trị viên hệ thống.

Kubernetes trừu tượng hóa toàn bộ các node worker trong cụm như một khối tài nguyên tính toán thống nhất, giúp các nhà phát triển không cần quan tâm đến chi tiết phần cứng cụ thể của từng node. Họ có thể triển khai ứng dụng một cách độc lập, chỉ cần mô tả yêu cầu tài nguyên, số bản sao, và các đặc tả logic khác.

Trong các trường hợp đặc biệt khi phần cứng các node không giống nhau — chẳng hạn một số node sử dụng SSD trong khi số khác dùng HDD — Kubernetes vẫn cho phép điều khiển linh hoạt thông qua các chỉ dẫn, giúp đảm bảo ứng dụng được lên lịch đúng trên phần cứng mong muốn. Điều này loại bỏ hoàn toàn nhu cầu chỉ định thủ công node triển khai như trong cách vận hành truyền thống.

#heading(level: 5, numbering: none, "Tối ưu hóa sử dụng hạ tầng")

Khi ứng dụng được triển khai thông qua Kubernetes, hệ thống có khả năng tự động chọn node phù hợp nhất để chạy mỗi Pod, dựa trên yêu cầu tài nguyên của Pod và mức sử dụng tài nguyên thực tế trên các node. Việc này tách rời hoàn toàn ứng dụng khỏi hạ tầng vật lý, giúp container có thể di chuyển linh hoạt trong cụm bất kỳ lúc nào.

Khả năng này không chỉ hỗ trợ đóng gói hiệu quả nhiều workload trên cùng một node (bin packing), mà còn tối ưu hóa việc sử dụng tài nguyên phần cứng một cách vượt trội so với thao tác thủ công. Trong khi con người khó có thể tính toán tổ hợp tối ưu cho hàng trăm ứng dụng và node, Kubernetes thực hiện điều đó một cách chính xác và tức thời.

#heading(level: 5, numbering: none, "Tự phục hồi và tăng tính sẵn sàng")

Một trong những giá trị cốt lõi của Kubernetes là khả năng tự giám sát và tự phục hồi. Khi một Pod hoặc node gặp sự cố (chẳng hạn như container ngừng phản hồi hoặc toàn bộ node bị lỗi), Kubernetes sẽ tự động lên lịch lại Pod đó sang node khác trong cụm mà không cần sự can thiệp của con người. 

Nhờ vậy, nhóm vận hành có thể tập trung vào việc sửa chữa phần cứng thay vì phải di chuyển ứng dụng bằng tay. Khi hệ thống có đủ năng lực dự phòng, Kubernetes thậm chí có thể duy trì trạng thái ổn định của ứng dụng mà không cần phản ứng khẩn cấp từ con người.

#heading(level: 5, numbering: none, "Tự động mở rộng")
Kubernetes không chỉ duy trì trạng thái triển khai ổn định, mà còn có thể tự động điều chỉnh quy mô của ứng dụng dựa trên tải thực tế. Bằng cách tích hợp với Horizontal Pod Autoscaler (HPA) hoặc Cluster Autoscaler, hệ thống có thể tăng hoặc giảm số lượng bản sao của một ứng dụng theo thời gian thực, dựa trên các chỉ số như CPU, bộ nhớ, hoặc số lượng truy cập.

Trong môi trường đám mây, Kubernetes còn có khả năng mở rộng toàn bộ cụm bằng cách tự động thêm hoặc loại bỏ node thông qua API của nhà cung cấp, giúp hệ thống phản ứng linh hoạt với biến động tài nguyên mà không cần sự giám sát liên tục từ nhóm vận hành.

#heading(level: 5, numbering: none, "Mã nguồn mở")
Kubernetes là một nền tảng mã nguồn mở được phát triển và duy trì bởi một cộng đồng rộng lớn, với sự tham gia của nhiều tập đoàn công nghệ hàng đầu. Việc là phần mềm mã nguồn mở mang lại những lợi ích quan trọng như:

- Khả năng kiểm soát và tuỳ chỉnh linh hoạt: Người dùng có thể tự điều chỉnh, mở rộng hoặc xây dựng các thành phần theo nhu cầu riêng, thay vì bị giới hạn bởi nhà cung cấp.

- Tính minh bạch và an toàn: Mã nguồn được công khai giúp tăng tính minh bạch, cho phép cộng đồng kiểm tra, phát hiện và xử lý lỗ hổng bảo mật kịp thời.

- Hệ sinh thái phong phú và hỗ trợ lâu dài: Hàng nghìn dự án và công cụ tương thích được phát triển xoay quanh Kubernetes, từ đó thúc đẩy sự đổi mới liên tục và cung cấp nhiều lựa chọn giải pháp cho người dùng.

- Không bị ràng buộc nhà cung cấp (vendor lock-in): Kubernetes cho phép triển khai trên nhiều nền tảng hạ tầng khác nhau (on-premises, multi-cloud, hybrid cloud) mà không phụ thuộc vào một nhà cung cấp đám mây duy nhất.

Với những lợi thế này, Kubernetes không chỉ là một công cụ kỹ thuật thuần túy, mà còn là nền tảng chiến lược giúp các tổ chức xây dựng các hệ thống ứng dụng hiện đại, mở và bền vững.

#pagebreak()
