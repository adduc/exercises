<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
            {{ __('Bookmarks') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white dark:bg-gray-800 overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 text-gray-900 dark:text-gray-100">
                    @if($bookmarks->isEmpty())
                        <p>{{ __("No bookmarks available.") }}</p>
                    @else
                        <ul>
                            @foreach($bookmarks as $bookmark)
                                <li class="p-4 border-b border-gray-200 dark:border-gray-700">
                                    <a href="{{ $bookmark->url }}" class="text-blue-500 hover:underline">
                                        {{ $bookmark->url }}
                                    </a>
                                </li>
                            @endforeach
                        </ul>
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-app-layout>