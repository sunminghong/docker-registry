docker run -d -p 5000:5000 --restart=always --name registry \
  -v `pwd`/certs:/certs \
  -v `pwd`/registry:/var/lib/registry \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
