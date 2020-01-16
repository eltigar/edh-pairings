FROM    python:3.7

ENV PYTHONUNBUFFERED 1

RUN apt-get update
RUN apt-get install -y swig libssl-dev dpkg-dev netcat

ADD requirements.txt /code/

WORKDIR /code

RUN pip3 install -r requirements.txt

COPY . /code/