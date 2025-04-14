<?php

namespace Tests\Feature\Http\Middleware;

// use Illuminate\Foundation\Testing\RefreshDatabase;

use App\Http\Middleware\BlockFatGetRequests;
use Illuminate\Http\Request;
use Tests\TestCase;

class BlockFatGetRequestsTest extends TestCase
{
    public function test_empty_get(): void
    {
        $middleware = new BlockFatGetRequests();
        $request = new Request(
            request: [],
            server: ['REQUEST_METHOD' => 'GET'],
        );

        $response = $middleware->handle($request, function ($req) {
            return response('Success', 200);
        });

        $this->assertEquals(200, $response->status());
        $this->assertEquals('Success', $response->getContent());
    }

    public function test_fat_get(): void
    {
        $middleware = new BlockFatGetRequests();
        $request = new Request(
            request: ['a' => 'b'],
            server: ['REQUEST_METHOD' => 'GET'],
        );

        $response = $middleware->handle($request, function ($req) {
            return response('Success', 200);
        });

        $this->assertEquals(403, $response->status());
        $this->assertEquals('{"error":"GET requests with body are not allowed."}', $response->getContent());
    }

    public function test_post(): void
    {
        $middleware = new BlockFatGetRequests();
        $request = new Request(
            request: ['a' => 'b'],
            server: ['REQUEST_METHOD' => 'POST'],
        );

        $response = $middleware->handle($request, function ($req) {
            return response('Success', 200);
        });

        $this->assertEquals(200, $response->status());
        $this->assertEquals('Success', $response->getContent());
    }
}
