provider "helm" {                                                                                                  
  kubernetes {                                                                                                     
    host                   = data.aws_eks_cluster.my-cluster.endpoint                                              
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.my-cluster.certificate_authority.0.data)            
    config_path            = "~/infra/eks-cluster/kubeconfig_my-cluster"                                           
  }                                                                                                                
}                                                                                                                  
                                                                                                                   
resource "helm_release" "jenkins" {                                                                                
  name       = "jenkins"                                                                                           
  repository = "https://charts.jenkins.io"                                                                         
  chart      = "jenkins"                                                                                           
                                                                                                                   
  values = [                                                                                                       
    "${file("jenkins-values.yaml")}"                                                                               
  ]                                                                                                                
                                                                                                                   
  set_sensitive {                                                                                                  
    name  = "controller.adminUser"                                                                                 
    value = "admin"                                                                                                
  }                                                                                                                
  set_sensitive {                                                                                                  
    name = "controller.adminPassword"                                                                              
    value = "admin"                                                                                                
  }                                                                                                                
  set_sensitive {                                                                                                  
    name = "adminPassword"                                                                                         
    value = "admin"                                                                                                
  }                                                                                                                
}
