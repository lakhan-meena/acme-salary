import React from "react"
import ReactDOM from "react-dom/client"
import { App as AntApp, ConfigProvider } from "antd"
import App from "./App"
import "antd/dist/reset.css"
import "./styles.css"

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: "#1f6b4a",
          colorInfo: "#1f6b4a",
          colorText: "#1c2420",
          colorBorder: "#e4dccf",
          borderRadius: 8,
          fontFamily: '"Figtree", "Segoe UI", sans-serif',
        },
      }}
    >
      <AntApp>
        <App />
      </AntApp>
    </ConfigProvider>
  </React.StrictMode>,
)
