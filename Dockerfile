FROM nginx
LABEL authors="vrba5597"
COPY index.html /var/www/html/

ENTRYPOINT ["top", "-b"]