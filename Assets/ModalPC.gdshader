shader_type canvas_item;

// ============================================================
// PANTALLA CRT DEL PC DEL TALLER
// ------------------------------------------------------------
// Se aplica al nodo "Pantalla" (TextureRect cuya textura es el
// SubViewport con la interfaz). Incrusta la interfaz dentro del
// tubo del monitor con:
//   - curvatura de barril (sigue la forma del tubo dibujado)
//   - scanlines + rejilla de fósforos
//   - aberración cromática en los bordes
//   - viñeta del tubo y tinte cálido
//   - parpadeo de refresco, banda de rodadura y ruido analógico
//   - reflejo del vidrio (recuperado del propio PNG del monitor)
//   - animación de encendido (power_on: 0 apagado -> 1 encendido)
// El script pantalla_crt.gd replica barrel()+inset para que el
// mouse interactúe exactamente donde la interfaz SE VE.
// ============================================================

uniform sampler2D monitor_tex : source_color; // pantalla_pc.png (para el reflejo del vidrio)
uniform vec4 monitor_region = vec4(0.0817, 0.0618, 0.8398, 0.8920); // sub-rect de la pantalla dentro del png
uniform float curve : hint_range(0.0, 0.5) = 0.12;   // curvatura del tubo
uniform float inset : hint_range(0.0, 0.2) = 0.02;   // margen entre la interfaz y el aro del tubo
uniform float brightness = 1.10;
uniform vec3 tint = vec3(1.03, 0.99, 0.93);          // fósforo cálido
uniform float aberration : hint_range(0.0, 2.0) = 0.22;
uniform float scan_strength : hint_range(0.0, 1.0) = 0.05;
uniform float grille_strength : hint_range(0.0, 1.0) = 0.02;
uniform float vignette : hint_range(0.0, 1.0) = 0.28;
uniform float glow : hint_range(0.0, 1.0) = 0.12;
uniform float flicker : hint_range(0.0, 0.2) = 0.008;
uniform float roll_strength : hint_range(0.0, 0.5) = 0.03;
uniform float roll_speed = 0.045;
uniform float noise_strength : hint_range(0.0, 0.3) = 0.012;
uniform float glare_threshold : hint_range(0.0, 1.0) = 0.30;
uniform float glare_strength : hint_range(0.0, 3.0) = 1.1;
uniform float power_on : hint_range(0.0, 1.0) = 1.0;

vec2 barrel(vec2 uv, float k) {
	vec2 p = uv - 0.5;
	p *= 1.0 + k * dot(p, p);
	return p + 0.5;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 443.8975);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	float m = 1.0 - 2.0 * inset;
	float pw = clamp(power_on, 0.0, 1.0);
	float colapso = max(pw * pw, 0.004); // encendido: la imagen nace como línea horizontal

	vec2 duv = barrel(UV, curve);
	vec2 ui_uv = (duv - vec2(inset)) / m;
	ui_uv.y = 0.5 + (ui_uv.y - 0.5) / colapso;

	vec4 salida = vec4(0.0);
	if (ui_uv.x >= 0.0 && ui_uv.x <= 1.0 && ui_uv.y >= 0.0 && ui_uv.y <= 1.0) {
		// Aberración cromática radial: R y B con curvaturas levemente distintas.
		vec2 uv_r = (barrel(UV, curve * (1.0 + 0.05 * aberration)) - vec2(inset)) / m;
		vec2 uv_b = (barrel(UV, curve * (1.0 - 0.05 * aberration)) - vec2(inset)) / m;
		uv_r.y = 0.5 + (uv_r.y - 0.5) / colapso;
		uv_b.y = 0.5 + (uv_b.y - 0.5) / colapso;

		vec4 base = texture(TEXTURE, ui_uv);
		vec3 col = vec3(
			texture(TEXTURE, clamp(uv_r, vec2(0.0), vec2(1.0))).r,
			base.g,
			texture(TEXTURE, clamp(uv_b, vec2(0.0), vec2(1.0))).b
		);

		// Scanlines horizontales + rejilla vertical de fósforos. Se calculan en
		// coordenadas de píxel de pantalla (FRAGCOORD) en vez de UV*constante:
		// así la frecuencia queda anclada al tamaño real en pantalla y no genera
		// aliasing/moiré que ensucie el texto al cambiar el tamaño del nodo.
		float scan = 1.0 - scan_strength * (0.5 + 0.5 * sin(FRAGCOORD.y * TAU / 3.0));
		float grille = 1.0 + grille_strength * sin(FRAGCOORD.x * TAU / 3.0);
		col *= scan * grille;

		// Emisión del fósforo: glow de zonas brillantes + tinte cálido.
		col += col * col * glow;
		col *= tint * brightness;

		// Vida analógica: parpadeo de refresco, banda que recorre y ruido.
		col *= 1.0 + flicker * sin(TIME * 110.0);
		float banda = exp(-pow((fract(duv.y - TIME * roll_speed) - 0.5) * 5.0, 2.0));
		col += col * banda * roll_strength;
		col += (hash12(UV * vec2(913.0, 527.0) + fract(TIME) * 91.7) - 0.5) * noise_strength;

		// Destello del encendido.
		col *= 1.0 + (1.0 - pw) * 2.5;

		salida = vec4(col, base.a);
	}

	// Viñeta del tubo: la imagen pierde luz hacia el borde del vidrio.
	vec2 pv = duv - 0.5;
	salida.rgb *= 1.0 - vignette * smoothstep(0.10, 0.50, dot(pv, pv));

	// Reflejo del vidrio: se re-agregan los brillos ya pintados del monitor
	// POR ENCIMA de la interfaz, como si estuviera detrás del cristal.
	vec2 mon_uv = monitor_region.xy + UV * monitor_region.zw;
	vec3 mon = texture(monitor_tex, mon_uv).rgb;
	salida.rgb += max(mon - vec3(glare_threshold), vec3(0.0)) * glare_strength * salida.a;

	COLOR = salida;
}
