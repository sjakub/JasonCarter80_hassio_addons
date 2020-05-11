ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# Install Python
RUN apk add --no-cache python3 jq \
    && pip3 install --no-cache --upgrade pip
COPY requirements.txt /tmp/
RUN pip3 install --requirement /tmp/requirements.txt
RUN sed -i 's|send_keypress(\[0x02\])|send_keypress(\[0x05, 0x02\])|' /usr/lib/python*/site-packages/concord232/concord.py

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]


