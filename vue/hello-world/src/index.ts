import { createApp } from "vue";
import MyComponent from "./my-component";

createApp(MyComponent).mount('#app')

if (typeof __ESBUILD_WATCH__ !== "undefined") {
    new EventSource('/esbuild').addEventListener('change', () => location.reload())
}
