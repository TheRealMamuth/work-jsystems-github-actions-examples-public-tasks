terraform {
  cloud {

    organization = "jsystems_jenkins_examples"

    workspaces {
      name = "gha_piotr_koska_example"
    }
  }
}
