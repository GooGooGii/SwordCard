import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { MobileOrientation } from "./ui/MobileOrientation";
import { game } from "./game/store";
import { installBackButton } from "./platform/backButton";
import "./fonts.css";
import "./styles.css";

installBackButton(() => game.run !== null);

const container = document.getElementById("root");
if (!container) throw new Error("#root not found");

createRoot(container).render(
  <StrictMode>
    <App />
    <MobileOrientation />
  </StrictMode>,
);
