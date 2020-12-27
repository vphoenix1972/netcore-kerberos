# netcore-kerberos

Build docker image:
```docker build -t netcore-kerberos -f Dockerfile .```

Run docker image:
```docker run -p 5100:80 -v /volume-with-kr5b-file:/mnt/volume --hostname linux-host-name netcore-kerberos```
