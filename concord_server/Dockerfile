ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# Install Python
RUN apk add --no-cache python3 jq \
    && pip3 install --no-cache --upgrade pip
COPY requirements.txt /tmp/
RUN pip3 install --requirement /tmp/requirements.txt

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]


