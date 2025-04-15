get:
	curl -v "localhost:8080" -X GET \
		--url-query "a[]=b" \
		--url-query "a[]=c"

get-with-body:
	curl -v "localhost:8080" -X GET \
		--url-query "a[]=b" \
		--url-query "a[]=c" \
		--data 'a=asdf'

post:
	curl -v "localhost:8080" -X POST \
		--url-query "a[]=b" \
		--url-query "a[]=c" \
		--data 'a=asdf'

error-external:
	curl -v "localhost:8080/error/external"

error-internal:
	curl -v "localhost:8080/error/internal"
