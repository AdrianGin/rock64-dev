# rock64-dev
Development for the Rock64

To remove all old images run:

docker system prune -a

docker build -f ./Dockerfile .

Ensure that images are deleted after they are used:
docker run --rm image_name





To enter Docker shell, enter:
make shell

