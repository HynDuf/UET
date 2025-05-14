- Chuong 1: Cac van de co ban ve Kubernetes
- Chuong 2: Kube-scheduler
  - https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/
- Chuong 3: Custom Kubernetes Scheduler
  - Prometheus
  - Giai thich Implement
  - Demo


- Chia viec:
  - Slide: 1 nguoi
  - Chuong 1: 1 nguoi
  - Chuong 2: 2 nguoi
  - Chuong 3: 
    - 1 nguoi: Huynh Tien Dung
    - Moi nguoi trong 5 nguoi viet ve 5 y o duoi
  

- Code them 5 y sau day (tuong ung voi 5 nguoi) vao custom scheduler:  
https://github.com/HynDuf/custom-kubernetes-scheduler#

- Enhance Filtering:
      1. Node Selector/Labels: Check if pod.Spec.NodeSelector matches the labels (node.Labels) on the candidate node. (Demonstrates: Understanding basic pod-to-node constraints).
    2. Taints and Tolerations: Check if the node has Taints (node.Spec.Taints) and if the pod Tolerates them (pod.Spec.Tolerations). Filter out nodes with taints the pod doesn't tolerate. (Demonstrates: Understanding node isolation and pod tolerance).
- Enhance Prioritization (Scoring): Go beyond just max available memory.
    3. Multi-Metric Scoring: Query Prometheus for multiple metrics (e.g., available CPU and available Memory). Normalize the scores (e.g., scale 0-10) and combine them, possibly with configurable weights. bestNodeName = weightMem * scoreMem + weightCPU * scoreCPU. (Demonstrates: More nuanced performance optimization).
        - Configurable Scoring Weights: If you implement multi-metric scoring (#3), make the weights used to combine different scores (e.g., memory vs CPU vs spreading) configurable via flags, environment variables, or a ConfigMap. (Demonstrates: User-tunable behavior).
    4. Node Affinity (Preferred): Implement preferredDuringSchedulingIgnoredDuringExecution from  pod.Spec.Affinity.NodeAffinity. Give bonus points in your scoring function to nodes that match preferred selectors. (Demonstrates: Integrating affinity preferences into scoring).
    