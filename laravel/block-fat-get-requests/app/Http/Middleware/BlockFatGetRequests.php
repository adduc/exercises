<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class BlockFatGetRequests
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        switch (true) {
            // verify request is either non-GET or has no body
            case $request->getRealMethod() !== 'GET':
            case !$request->request->getIterator()->valid():
                return $next($request);

            // if it is a GET request with a body, block it
            default:
                $msg = 'GET requests with body are not allowed.';
                return response()->json(['error' => $msg], 403);
        }
    }
}
