---
apiVersion: v1
kind: Namespace
metadata:
  name: pan
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: pan
  name: panweb-deploy
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: panweb
  replicas: 2 
  template:
    metadata:
      labels:
        app.kubernetes.io/name: panweb
    spec:
      containers:
      - image: lderjim/web:latest
        imagePullPolicy: Always
        name: panweb
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  namespace: pan
  name: panweb-service
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: NodePort
  selector:
    app.kubernetes.io/name: panweb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: pan
  name: panproxy-deploy
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: panproxy
  replicas: 2 
  template:
    metadata:
      labels:
        app.kubernetes.io/name: panproxy
    spec:
      containers:
      - image: lderjim/proxy:latest
        imagePullPolicy: Always
        name: panproxy
        ports:
        - containerPort: 443
        env:
        - name: BASIC_AUTH_USERNAME
          value: panuser
        - name: BASIC_AUTH_PASSWORD
          value: panpass
        - name: STATIC_TOKEN
          value: OWCBTo9hW7buI1cOS022
        - name: PROXY_PASS
          value: http://panweb-service/
        volumeMounts:
        - name: certs
          mountPath: /etc/nginx/pan.crt
          subPath: pan.crt
        - name: certs
          mountPath: /etc/nginx/pan.key
          subPath: pan.key
      volumes:
      - name: certs
        secret:
          secretName: certificate
---
apiVersion: v1
kind: Service
metadata:
  namespace: pan
  name: panproxy-service
spec:
  ports:
    - port: 443
      targetPort: 443
      protocol: TCP
  type: NodePort
  selector:
    app.kubernetes.io/name: panproxy
---
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: certificate
  namespace: pan
data:
  pan.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURyVENDQXBXZ0F3SUJBZ0lVY2k3Rjh5QlZtOEN6OGFKTDlkNmpUd0JvZ2Rvd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1pqRUxNQWtHQTFVRUJoTUNWVk14RVRBUEJnTlZCQWdNQ0U1bGR5QlpiM0pyTVJBd0RnWURWUVFIREFkQwpkV1ptWVd4dk1Rd3dDZ1lEVlFRS0RBTlFRVTB4Q3pBSkJnTlZCQXNNQWtsVU1SY3dGUVlEVlFRRERBNTNkSEpoCmJtTm9aV3hzTG1OdmJUQWVGdzB5TVRBME1URXhOak14TURoYUZ3MHlNakEwTVRFeE5qTXhNRGhhTUdZeEN6QUoKQmdOVkJBWVRBbFZUTVJFd0R3WURWUVFJREFoT1pYY2dXVzl5YXpFUU1BNEdBMVVFQnd3SFFuVm1abUZzYnpFTQpNQW9HQTFVRUNnd0RVRUZOTVFzd0NRWURWUVFMREFKSlZERVhNQlVHQTFVRUF3d09kM1J5WVc1amFHVnNiQzVqCmIyMHdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEb0kzdVo0VktXUmFUanBRYVAKRzV1TlBaeDhJUXprVDlnNzBGYnNGRlBHMjVjdHdxeU93ZmdUblV4WU03Yk9hUE1mT3NrZGdMVVNrMXlFUnRCdwpESldnYmNBekxWUlZWanNUc1VISXZCbXBrRWtMYWF0Qmg4dXRKckJiSlFBcHRJRENxN29DTTFHVklkNW50OVZiCnNWNkR3TFNNeDFiQm1KLzVEQk1PSktWSTBPUjlwZVAzK3ppcTZMT1BCS0dCZDByOHYxMU0xaVAyU3ZOVlVYbUEKUllsRitRUHBWU1hidjFjYVM1c09wMVhrM1F2M3JRK3BuZEZ0QXlnMGkxZUVNNDkwdTVZZUVhekgvMFdTUTMzWgpjZzVGZmVWQ3RGUmJ2eWNzZ0h3engyYUpjRzQ3eWZpTjc1RTBjNmFGbnkyemJnVjR3ejVxeElXZlN0TGNrQmlQCjNqMU5BZ01CQUFHalV6QlJNQjBHQTFVZERnUVdCQlNydVpyTDY5cWdVQjZjejhGdTZiZUwzYnJIUWpBZkJnTlYKSFNNRUdEQVdnQlNydVpyTDY5cWdVQjZjejhGdTZiZUwzYnJIUWpBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUEwRwpDU3FHU0liM0RRRUJDd1VBQTRJQkFRREp0eDdNdGxwV2s1T2xmMGN4WjJSWFRLMDNnaHdiOVo2Q0tCcUJPanloClJTY0pqcDM5ZXdrWkZOR3U5MDIyemphNnBQbW1XMy8vaU9sSkc5b3FGc1MxUFo2blBBUWFjWjN4Z0IzQ3gzZjkKSUxpUzFJYUMzOXA0aWtXcE5pZzE5eDFVeXNxOExrR1M5OTUxaWFuZWw5cWFTeDh5SXFwTWkvTXRyWTdQajV1bApaMWxEWkVXcTBSOTF4RXd0cThsb2NDQ01ueGVMTTNybzJIWnl4SXhuMGpLd0t4YVZQTWNteXpOOTN1VUZqa1pYCk5qVTRMWEppbzIzOFZrZHhwQWh2ZGJDSERZRGhhT0szOU5IZGxOaGt1eGYyc0g2aU8xMllua2tQREJObG5xWHkKWWxEMFM4L1Q2dFdnZWh5M2NmeFU0WGhuUS8zcVZhVUJMaFJaMzFZVk90WWIKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  pan.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRRG9JM3VaNFZLV1JhVGoKcFFhUEc1dU5QWng4SVF6a1Q5ZzcwRmJzRkZQRzI1Y3R3cXlPd2ZnVG5VeFlNN2JPYVBNZk9za2RnTFVTazF5RQpSdEJ3REpXZ2JjQXpMVlJWVmpzVHNVSEl2Qm1wa0VrTGFhdEJoOHV0SnJCYkpRQXB0SURDcTdvQ00xR1ZJZDVuCnQ5VmJzVjZEd0xTTXgxYkJtSi81REJNT0pLVkkwT1I5cGVQMyt6aXE2TE9QQktHQmQwcjh2MTFNMWlQMlN2TlYKVVhtQVJZbEYrUVBwVlNYYnYxY2FTNXNPcDFYazNRdjNyUStwbmRGdEF5ZzBpMWVFTTQ5MHU1WWVFYXpILzBXUwpRMzNaY2c1RmZlVkN0RlJidnljc2dId3p4MmFKY0c0N3lmaU43NUUwYzZhRm55MnpiZ1Y0d3o1cXhJV2ZTdExjCmtCaVAzajFOQWdNQkFBRUNnZ0VBTUc1ZXRpOE5WTzY0eFFuRUFZMW4rYUsyQ0N1NURkVWVydlA3Zm91TEl2emoKWUpleCtxSzdTQlJVUGo2ajBCS1RUcHVzSSt5YldvSEdGbzdUbzl6c1Jxay9KUzQ2M3diN2tsTXovMVpISUZwSwo4d2VieERNNXFpbGROOWJUWHVBYTBRS1U3eXFYeGI1b01VbG9TUllMT3YrMGEzNlhPaExHcFdZQWY3M2pnZm8xCk5FZGdvUGJhWnR5eUpnWE9xdHJKaWt2S0hUU1Vvd0JqZG01K3k5TEM2ZDF5ME1sT041djA4UjhHRzRMeDhwTFoKMkt4eHJrbEhQYnZ3aDJhcEdzSEpqQjZ3bGRiMllRTnRvZUNrNFRLYktlM3psOUkxYzBrMUdjbDM3cjZrQXlQNQpJcmdrTjBQUm93ZVZjTFV1STdMa2JaUzNQZ2dacEdGMzVQR2lXeEhQZlFLQmdRRDl1dlprYnRNRXZDdGJRM2VwCjBjdTIyNkF2TmF4YjluKzRrYThhTG9PWm5oWGxrUzZjNTlZZkRJRTR2NWtrOVkxUHl1NW1YRGtwc3BNaElBdUcKczgwVndvVURKc0MrUllFUHY2NS9qbDg1eG1QODZCczFKbm1LUE5takhqckRSQkR4eFc2dFJXTEpxVW5sampKTgpreWpuYjNOMEpSZmVRbW15dHBLeWJsU0lId0tCZ1FEcU54TmpKUytOM1ZnWExvTVdhc0xPZUFKYmpOTVBJc1NjCms2RVRnUHcrbmluRU9kcTVzTCtNeGl6MDNOZ041UEZUWDBYVndYN1d2ZGVCUXB4TmU1L2JFNHkrTk5Sclg4UHgKQW4wemJxTmlRZHNqWkZHd1B3T3B6SWtRbk5tWUQxdDVhbzVReDhXekJxZjArVCtmOGgzNzI2UzlaVHdzQWFpaQpEMDV0TnI5OUV3S0JnUURzeTg3bHZsUXJ5QjFDaUQybWZFaDl1SXpQWW0wZ1NuVzZZQ1FsOENFYmZlRDdwYm4xCjc1dnkwQzNOTTJzT2hpaEN2cVl0VzRaeHR0bi9BVFFnbTY4YnpyVnFVb0Z4VWRaNFJ6RG9sSXVrbE5WK0UzUkkKNzBaZzBCZGhWM1lLQkgwMzFrVkxha1VlNVdJMDNiZHVsSmVKSG9lR2JwUE85dlpFTm9YRUJwblhpd0tCZ0dQZwpacUVSMjJ5SXBpY0VpNXdFbk53RTZ5UjFNZyt6U05wb1Rma09PUUxPMllxM0RTSEFVSDdNaDZGSGg4NnRBWWdICkNiVzBsTTBvR1gwaWxacXBEQ3NVOUNDc1VLVVZLbTVkSEZ6UllsVGxObmlxTC9lVGQ1RnlDa1VPVGUvOUpJbnIKT1pNVERhaGhQMEJGQmEvRVJLc0JLQWduNG5mMW9SNnlua1FPWTZ3SEFvR0FHMHpjTzFHQ2Vxb3dWYU5SV3Z6VwpIaVFQSW1hUEJGQm1lUk1LVldEbWlrNUVnMDdPbTBaOVZMOUJGeGpiTkZHQ2lLL3o4cXprYWIvbCswVFNHMXJUCmxIc2Nld2Z2M2tQWGxKaWNDNkpESWgrV01PeE84bXBkYyt6MkxyU0NNRTFlNmJmaUx5c0lvSXhyNldqMDA5QlQKUkprdWRnNDQvZlU2WkpWcUdtMm9WNEk9Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  namespace: pan
  name: pan-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443},{"HTTP":80}]'
    alb.ingress.kubernetes.io/certificate-arn: "REPLACE_ACM_ARN"
spec:
  rules:
    - http:
        paths:
          - path: /*
            backend:
              serviceName: panproxy-service
              servicePort: 443
