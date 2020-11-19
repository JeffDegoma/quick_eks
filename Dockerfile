FROM amazon/aws-cli:2.0.43

WORKDIR /work

COPY . .

RUN chmod +x  ./init.sh

RUN ./init.sh

