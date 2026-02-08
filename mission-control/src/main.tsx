import React from "react";
import ReactDOM from "react-dom/client";
import { DemoProvider } from "./demo-provider";
import App from "./App";
import "./styles/globals.css";

const convexUrl = import.meta.env.VITE_CONVEX_URL as string | undefined;

async function render() {
  const root = ReactDOM.createRoot(document.getElementById("root")!);

  if (convexUrl) {
    // Real Convex mode — dynamic imports to avoid bundling Convex in demo builds
    const { ConvexProvider, ConvexReactClient } = await import("convex/react");
    const { ConvexDataProvider } = await import("./convex-data-provider");
    const client = new ConvexReactClient(convexUrl);
    root.render(
      <React.StrictMode>
        <ConvexProvider client={client}>
          <ConvexDataProvider>
            <App />
          </ConvexDataProvider>
        </ConvexProvider>
      </React.StrictMode>
    );
  } else {
    // Demo mode — no Convex required
    console.info(
      "[Mission Control] Running in demo mode. Set VITE_CONVEX_URL for real-time data."
    );
    root.render(
      <React.StrictMode>
        <DemoProvider>
          <App />
        </DemoProvider>
      </React.StrictMode>
    );
  }
}

render();
