<?php

namespace Tests\Feature;

use App\Http\Requests\QueryRequest;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

/**
 * The FormRequestServiceProvider will call the validation
 * when resolving the QueryRequest, which should throw an
 * exception due to the unsatisfied validation rules.
 */
class QueryRequestTest extends TestCase
{
    public function test_minimal_success()
    {
        $request = $this->setRequest(
            query: ['example' => md5(random_bytes(32))],
        );

        $query_request = app()->make(QueryRequest::class);

        $this->assertEquals(
            $request->query->get('example'),
            $query_request->validated()['example'],
        );
    }

    public function test_maximum_success()
    {
        $request = $this->setRequest(
            query: ['example' => md5(random_bytes(32))],
            request: ['example' => md5(random_bytes(32))],
            server: ['REQUEST_METHOD' => 'POST'],
        );

        $query_request = app()->make(QueryRequest::class);

        $this->assertEquals(
            $request->query->get('example'),
            $query_request->validated()['example'],
        );
    }

    public function test_empty_payload()
    {
        try {
            app()->make(QueryRequest::class);
            $this->fail("ValidationException was not thrown");
        } catch (ValidationException $e) {
            $this->assertNotEmpty($e->validator->errors()->get('example'));
        }
    }

    public function test_post_data()
    {
        $this->setRequest(
            request: ['example' => md5(random_bytes(32))],
            server: ['REQUEST_METHOD' => 'POST'],
        );

        try {
            app()->make(QueryRequest::class);
            $this->fail("ValidationException was not thrown");
        } catch (ValidationException $e) {
            $this->assertNotEmpty($e->validator->errors()->get('example'));
        }
    }

    protected function setRequest(
        array $query = [],
        array $request = [],
        array $server = []
    ) {
        $obj = app(Request::class);

        $obj->query->replace($query);
        $obj->request->replace($request);
        $obj->server->replace($server);

        return $obj;
    }
}
