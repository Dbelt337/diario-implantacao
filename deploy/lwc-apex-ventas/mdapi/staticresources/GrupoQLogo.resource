<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 490" role="img" aria-label="GrupoQ">
  <defs>
    <linearGradient id="gqBlue" x1="0" y1="0" x2="0.35" y2="1">
      <stop offset="0" stop-color="#8FBDE9"/>
      <stop offset="0.5" stop-color="#2E6DC0"/>
      <stop offset="1" stop-color="#173F8F"/>
    </linearGradient>
    <linearGradient id="gqRed" x1="0.2" y1="0" x2="0.6" y2="1">
      <stop offset="0" stop-color="#7C1218"/>
      <stop offset="0.55" stop-color="#C0392B"/>
      <stop offset="1" stop-color="#E98C7E"/>
    </linearGradient>
    <linearGradient id="gqTail" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#8E1B1F"/>
      <stop offset="1" stop-color="#D9534F"/>
    </linearGradient>
  </defs>
  <!-- swoosh rojo: lado derecho, de oscuro arriba a claro abajo -->
  <path d="M 222.6 62 A 130 130 0 1 1 135 302.6"
        fill="none" stroke="url(#gqRed)" stroke-width="56" stroke-linecap="round"/>
  <!-- swoosh azul: sobre el rojo, cubre el lado izquierdo -->
  <path d="M 265 77.4 A 130 130 0 1 0 177.4 318"
        fill="none" stroke="url(#gqBlue)" stroke-width="56" stroke-linecap="round"/>
  <!-- cola de la Q -->
  <rect x="269" y="220" width="52" height="150" fill="url(#gqTail)"
        transform="rotate(-45 295 295)"/>
  <text x="200" y="462" text-anchor="middle"
        font-family="Helvetica, Arial, sans-serif" font-size="56"
        fill="#173F8F" letter-spacing="10">GRUPO<tspan font-weight="bold">Q</tspan></text>
</svg>
