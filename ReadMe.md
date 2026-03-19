# Dokumentacja:

## Github actions:
0. https://docs.github.com/en/actions
1. https://docs.github.com/en/actions/get-started/quickstart
2. https://docs.github.com/en/actions/get-started/understand-github-actions
3. https://docs.github.com/en/actions/get-started/continuous-integration
4. https://docs.github.com/en/actions/get-started/continuous-deployment
5. https://docs.github.com/en/actions/get-started/actions-vs-apps
6. https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
7. https://docs.github.com/en/actions/tutorials/use-containerized-services/use-docker-service-containers
8. https://docs.github.com/en/actions/tutorials
9. https://docs.github.com/en/actions/get-started/understand-github-actions
10. https://docs.github.com/en/billing/concepts/product-billing/github-actions
11. https://docs.github.com/en/actions/reference/limits

## 01 Githuba actions bulding blocks
1. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax

## 02 Event Triggers:
1. https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
2. https://crontab.cronhub.io/

## 03 Workflow runners:
1. https://docs.github.com/en/actions/reference/runners/github-hosted-runners
   - https://docs.github.com/en/actions/concepts/runners/github-hosted-runners
2. https://docs.github.com/en/actions/reference/runners/larger-runners
   - https://docs.github.com/en/actions/concepts/runners/larger-runners
3. https://docs.github.com/en/actions/reference/runners/self-hosted-runners
   - https://docs.github.com/en/actions/concepts/runners/self-hosted-runners
4. https://docs.github.com/en/actions/how-tos/manage-runners/github-hosted-runners/use-github-hosted-runners
5. https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners
   - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners
   - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners
   - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels
     - https://docs.github.com/en/actions/concepts/runners/actions-runner-controller#using-arc-runners-in-a-workflow
     - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels#creating-a-custom-label-for-a-repository-runner
     - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels#creating-a-custom-label-for-an-organization-runner
     - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels#assigning-a-label-to-a-repository-runner
     - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels#assigning-a-label-to-an-organization-runner
     - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels#removing-a-custom-label-from-a-repository-runner
     - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels#removing-a-custom-label-from-an-organization-runner
     - https://docs.github.com/en/actions/how-tos/manage-runners/larger-runners/use-custom-images
   - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/customize-containers
   - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/configure-the-application
   - https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/use-in-a-workflow

6. https://docs.github.com/en/actions/how-tos/manage-runners/larger-runners/manage-larger-runners
7. https://docs.github.com/en/actions/reference/workflows-and-actions/variables
8. https://docs.github.com/en/actions/how-tos/write-workflows
9. https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows

## 04 Using Third-Party Actions:
1. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsuses
2. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_iduses
3. https://github.com/marketplace?type=actions
4. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/set-default-values-for-jobs
5. https://docs.docker.com/build/ci/github-actions/
6. https://docs.docker.com/build/ci/github-actions/annotations/
7. https://docs.docker.com/build/ci/github-actions/attestations/
8. https://docs.docker.com/build/ci/github-actions/checks/
9. https://docs.docker.com/build/ci/github-actions/secrets/
10. https://docs.docker.com/build/ci/github-actions/build-summary/
11. https://docs.docker.com/build/ci/github-actions/configure-builder/
12. https://docs.docker.com/build/ci/github-actions/cache/
13. https://docs.docker.com/build/ci/github-actions/copy-image-registries/
14. https://docs.docker.com/build/ci/github-actions/export-docker/
15. https://docs.docker.com/build/ci/github-actions/local-registry/
16. https://docs.docker.com/build/ci/github-actions/multi-platform/
17. https://docs.docker.com/build/ci/github-actions/named-contexts/
18. https://docs.docker.com/build/ci/github-actions/push-multi-registries/
19. https://docs.docker.com/build/ci/github-actions/reproducible-builds/
20. https://docs.docker.com/build/ci/github-actions/share-image-jobs/
21. https://docs.docker.com/build/ci/github-actions/manage-tags-labels/
22. https://docs.docker.com/build/ci/github-actions/test-before-push/
24. https://docs.docker.com/build/ci/github-actions/update-dockerhub-desc/
25. https://docs.github.com/en/actions/reference/workflows-and-actions/dockerfile-support
26. https://github.com/docker/bake-action
27. https://github.com/marketplace/actions/docker-buildx-bake

## 05 Event Filters and Activity Types
1. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpull_requestpull_request_targetbranchesbranches-ignore
2. https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows

## 06 Using Context
1. https://docs.github.com/en/actions/reference/workflows-and-actions/contexts
2. https://docs.github.com/en/actions/concepts/workflows-and-actions/contexts
3. https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#available-contexts
4. https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax#inputs
5. https://docs.github.com/en/enterprise-cloud@latest/actions/reference/workflows-and-actions/contexts#inputs-context
6. https://docs.github.com/en/enterprise-cloud@latest/actions/reference/workflows-and-actions/workflow-syntax#run-name

## 07 Using Expressions
1. https://docs.github.com/en/actions/concepts/workflows-and-actions/expressions
2. https://docs.github.com/en/actions/reference/workflows-and-actions/expressions

## 08 Expressions and Variables
1. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables
2. https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments
3. https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments
4. https://docs.github.com/en/actions/reference/workflows-and-actions/variables
5. https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments

## 09 Functions
1. https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#functions
2. https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#status-check-functions
3. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands

## 10 Controlling the Execution Flow
1. https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions
2. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-jobs
3. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idneeds
4. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs
5. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepscontinue-on-error
6. https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#example-returning-a-json-data-type
7. https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions
8. https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#status-check-functions
9. https://stackoverflow.com/questions/76750973/how-to-execute-a-job-that-needs-a-job-that-was-skipped
10. https://github.com/actions/runner/issues/1540

## 11 Inputs
1. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_callinputs
2. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_callinputsinput_idtype
3. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs
4. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputsinput_idrequired
5. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputsinput_idtype
6. https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#inputs-context
7. https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_call
8. https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_dispatch
9. https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax#inputs
10. https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
11. https://github.com/marketplace/actions/interactive-inputs#interactive-inputs

## 12 Outputs
1. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs
2. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#setting-an-output-parameter
3. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
4. https://docs.github.com/en/actions/reference/workflows-and-actions/contexts
5. https://docs.github.com/en/actions/reference/workflows-and-actions/expressions
6. https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows

## 13 Caching
1. https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching
2. https://github.com/actions/cache
3. https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manage-caches
4. https://docs.docker.com/build/cache/backends/gha/

## 14 Artifacts
1. https://github.blog/news-insights/product-news/get-started-with-v4-of-github-actions-artifacts/
2. https://docs.github.com/en/actions/tutorials/store-and-share-data
3. https://github.com/actions/upload-artifact
4. https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts
5. https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts
6. https://docs.github.com/en/rest/actions/artifacts?apiVersion=2022-11-28
7. https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts

## 15 Matrices
1. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations
2. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstrategymatrix
3. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstrategy


## 16 Enviroments
1. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idenvironment
2. https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments
3. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/deploy-to-environment
4. https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments
5. https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments

## 17 Custom Actions
1. https://docs.github.com/en/actions/concepts/workflows-and-actions/custom-actions
2. https://docs.github.com/en/actions/how-tos/create-and-publish-actions
3. https://docs.github.com/en/actions/how-tos/create-and-publish-actions/manage-custom-actions
4. https://docs.github.com/en/actions/tutorials/use-containerized-services/create-a-docker-container-action
5. https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/run-jobs-in-a-container
6. https://docs.github.com/en/actions/concepts/workflows-and-actions/custom-actions

## Secrets:
1. https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets
2. https://docs.github.com/en/actions/reference/security/secure-use

## BVest Practices
0. https://docs.github.com/en/copilot/get-started/best-practices
1. https://docs.github.com/en/repositories/creating-and-managing-repositories/best-practices-for-repositories
2. https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects
3. https://docs.github.com/en/contributing/writing-for-github-docs/best-practices-for-github-docs
4. https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/best-practices-for-organizations
5. https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/best-practices-for-creating-a-github-app

## reuseing workflows
1. https://docs.github.com/en/actions/concepts/workflows-and-actions/reusing-workflow-configurations
2. https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows


3: https://docs.github.com/en/actions/reference/workflows-and-actions/expressions?search-overlay-input=functions

4: https://docs.github.com/en/actions/reference/workflows-and-actions/expressions?search-overlay-input=functions#functions

6: https://docs.github.com/en/billing/concepts/product-billing/github-actions

7: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository


## Dodatkowe materiały:
1. https://registry.terraform.io/providers/integrations/github/latest/docsJust a few more. Repository. Okay. As present at sea, Dalai. Attack the environments accession. Or secret. Variables. Environment. Actually test test. Variables test. Test. 2 The momentum. Declarati Kodu.
