PROJECT_NUMBER=1082852559331
USER_ID=trainocat-1773726914421


gcloud config set run/region us-central1
gcloud config set functions/region us-central1

gcloud services enable \
eventarc.googleapis.com \
run.googleapis.com \
cloudfunctions.googleapis.com \
cloudbuild.googleapis.com \
artifactregistry.googleapis.com \
pubsub.googleapis.com \
firestore.googleapis.com \
storage.googleapis.com

echo "Waiting for APIs to be ready..."

sleep 60

npm init -y
npm install @google-cloud/firestore

gcloud firestore databases create \
--location=us-central1 \
--type=firestore-native

sleep 30

node initFirestore.js

gcloud pubsub topics create order-created
gcloud pubsub topics create order-accepted
gcloud pubsub topics create order-rejected
gcloud pubsub topics create delivery-start

echo "Create Artifact Registry"

gcloud config set artifacts/location us-central1

gcloud artifacts repositories create figgy-repo \
--repository-format=docker \
--location=us-central1 || true

gcloud auth configure-docker us-central1-docker.pkg.dev -q

echo "Deploy order-service"

cd order-service

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/storage.admin"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/cloudbuild.builds.builder"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/datastore.user"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/pubsub.publisher"

sleep 30

npm init -y
npm install express @google-cloud/firestore @google-cloud/pubsub

gcloud builds submit \
--tag us-central1-docker.pkg.dev/$USER_ID/figgy-repo/order-service

gcloud run deploy order-service \
--image us-central1-docker.pkg.dev/$USER_ID/figgy-repo/order-service \
--allow-unauthenticated \
--region us-central1

cd ..


echo "Deploy supplierFn"

cd supplier-fn

npm init -y
npm install @google-cloud/firestore @google-cloud/pubsub

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/cloudfunctions.admin"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/run.admin"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/storage.admin"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/eventarc.admin"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-eventarc.iam.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud projects add-iam-policy-binding $USER_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud functions deploy supplierFn \
--gen2 \
--runtime nodejs22 \
--region us-central1 \
--trigger-topic order-created \
--entry-point supplierFn \
--source .

gcloud run services add-iam-policy-binding supplierfn \
--region us-central1 \
--member="allUsers" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding supplierfn \
--region us-central1 \
--member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-eventarc.iam.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding supplierfn \
--region us-central1 \
--member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/cloudtasks.admin"

gcloud projects add-iam-policy-binding $USER_ID \
--member="user:rakesh_bb001222-2440-4ffa-bb9f-82f324a9998a@spoclearngcp.nuvelabs.com" \
--role="roles/iam.serviceAccountUser"

gcloud artifacts repositories list --location=us-central1

cd ..


echo "Deploy deliveryFn"

cd delivery-fn

npm init -y
npm install @google-cloud/firestore

gcloud functions deploy deliveryFn \
--gen2 \
--runtime nodejs22 \
--region us-central1 \
--trigger-topic order-accepted \
--entry-point deliveryFn \
--source .

curl -X POST https://order-service-$PROJECT_NUMBER.us-central1.run.app/order \
-H "Content-Type: application/json" \
-d '{"userId":"user1","supplierId":"sup1"}'

gcloud run services add-iam-policy-binding deliveryfn \
--region us-central1 \
--member="allUsers" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding supplierfn \
--region us-central1 \
--member="allUsers" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding supplierfn \
--region us-central1 \
--member="allUsers" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding deliveryfn \
--region us-central1 \
--member="allUsers" \
--role="roles/run.invoker"

gcloud projects describe $USER_ID \
--format="value(projectNumber)"

gcloud run services add-iam-policy-binding supplierfn \
--region us-central1 \
--member="serviceAccount:service-123456789012@gcp-sa-eventarc.iam.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding deliveryfn \
--region us-central1 \
--member="serviceAccount:service-123456789012@gcp-sa-eventarc.iam.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding supplierfn \
--region us-central1 \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/run.invoker"

gcloud run services add-iam-policy-binding deliveryfn \
--region us-central1 \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/run.invoker"

echo "Setup Done"