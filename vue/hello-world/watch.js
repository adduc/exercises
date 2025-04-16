import * as esbuild from 'esbuild';

let ctx = await esbuild.context({
    entryPoints: [
        "src/index.ts",
    ],
    bundle: true,
    outdir: "dist",
    treeShaking: true,
    minify: true,
    alias: {
        'vue': 'vue/dist/vue.esm-bundler.js',
    },
    jsxFactory: 'h',
    jsxFragment: 'Fragment',
    define: {
        "__ESBUILD_WATCH__": "true",
        "__VUE_OPTIONS_API__": "false",
        "__VUE_PROD_DEVTOOLS__": "false",
        "__VUE_PROD_HYDRATION_MISMATCH_DETAILS__": "false",
    }
})

await ctx.watch();

let { host, port } = await ctx.serve({
    servedir: "dist",
    host: "localhost",
    port: 8000,
});

console.log(`Server is running at http://${host}:${port}`);
