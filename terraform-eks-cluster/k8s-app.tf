# Creates application deployment on k8s
data "kubectl_path_documents" "app" {
    pattern = "pan.yaml"
}

resource "kubectl_manifest" "app" {
    count     = length(data.kubectl_path_documents.app.documents)
    yaml_body = element(data.kubectl_path_documents.app.documents, count.index)
}
