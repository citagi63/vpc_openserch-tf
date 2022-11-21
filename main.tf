resource "null_resource" "provision-builder" {
  triggers = {
    dir_sha1    = sha1(join("", [for f in fileset(.hack/main.tf, "hack/**") : filesha1(f)]))
  }

  provisioner "local-exec" {
    command = "echo Touché"
  }
}
