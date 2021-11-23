output "ecr_info" {                                                                                                
 value       = aws_ecr_repository.cluster_app.arn                                                                  
 description = "container registry information for jenkins reference"                                              
}                                                                                                                  
                                                                                                                   
output "ecr_info2" {                                                                                               
                                                                                                                   
 value = aws_ecr_repository.cluster_app.registry_id                                                                
 description = "aa"                                                                                                
}                                                                                                                  
                                                                                                                   
output "ecr_info3" {                                                                                               
                                                                                                                   
 value = aws_ecr_repository.cluster_app.repository_url                                                             
 description = "bb"                                                                                                
}                    
