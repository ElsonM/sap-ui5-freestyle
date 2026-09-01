import { defineConfig } from "vitest/config";

export default defineConfig({
    test: {
        environment: "node",
        include: ["webapp/test/unit/**/*.test.ts"],
        setupFiles: ["./webapp/test/unit/setup.ts"]
    }
});
