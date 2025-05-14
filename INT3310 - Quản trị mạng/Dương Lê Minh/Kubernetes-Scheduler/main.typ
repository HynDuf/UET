#import "template.typ": *

#show: project.with(
  title: "Bộ lập lịch tùy chỉnh và thuật toán cấp phát tài nguyên cho Kubernetes",
  authors: (
    (name: "Huỳnh Tiến Dũng", 
    msv: "21020007"),
    (name: "Vũ Huy Hoàng", 
    msv: "22021108"),
    (name: "Nguyễn Đăng Quân", 
    msv: "22021121"),
    (name: "Nguyễn Hồng Quân", 
    msv: "22021122"),
    (name: "Nguyễn Chí Thanh", 
    msv: "22021123"),
  ), 
  instructors: (
    (name: "TS. Dương Lê Minh"),
  ),
)

#include "src/04_bang_phan_chia.typ"

#counter(page).update(1)
#set page(numbering: "1")
#set heading(numbering: "1.1.", supplement: "Chương")

#include "src/05_chuong_1.typ"
#include "src/06_chuong_2.typ"
#include "src/07_chuong_3.typ"
// #bibliography("ref.bib", style: "elsevier-vancouver")

#pagebreak()

#heading(numbering: none)[Tài liệu tham khảo]

-  #link("https://www.youtube.com/watch?v=IYcL0Un1io0")[GopherCon 2016: Kelsey Hightower - Building a custom Kubernetes scheduler]

-  #link("https://github.com/kelseyhightower/scheduler")[Hightower Toy Scheduler Source Code]
-  #link("https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/")[Kubernetes Documentation: Scheduler]
-  #link("https://prometheus.io/docs/introduction/overview/")[Prometheus Documentation]

- #link("https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/")[Pod Lifecycle, Kubernetes docs]

- #link("https://www.docker.com/resources/what-container/")[What is a Container? | Docker]

- #link("https://kubernetes.io/docs/concepts/overview/")[Overview, Kubernetes docs]

- #link("https://www.cncf.io/projects/kubernetes/")[Kubernetes, CNCF]

- #link("https://www.redhat.com/en/engage/kubernetes-scheduling-future-cloud-scale-free-ebook")[Kubernetes: Scheduling the Future at Cloud Scale (Free eBook)]

- #link("https://cloud.google.com/monitoring")[G. Google Cloud Monitoring. Cloud Monitoring]

- #link("https://doi.org/10.23919/CNSM55787.2022.9965056")[D. Spatharakis, et al. Distributed Resource Autoscaling in Kubernetes Edge Clusters]

- #link("https://www.atlassian.com/microservices/microservices-architecture/kubernetes-vs-docker")[J. Campbell. Kubernetes vs. docker]

- #link("https://cloud.google.com/kubernetes-engine/docs")[Google kubernetes engine documentation]

- #link("https://prometheus.io/docs/guides/node-exporter/")[Node Exporter]

- #link("https://blog.freshtracks.io/a-deep-dive-into-kubernetes-metrics-part-2-c869581e9f29")[A Deep Dive into Kubernetes Metrics]

- #link("https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/")[The Kubernetes Authors. Managing Compute Resources for Containers]
