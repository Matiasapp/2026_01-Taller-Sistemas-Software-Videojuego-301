shader_type canvas_item;

uniform sampler2D interface_texture;
uniform float curve : hint_range(0.0, 3.0) = 3; // Ajusta este valor

// Función que aplica distorsión de barril a las coordenadas UV
vec2 distort(vec2 uv) {
    vec2 p = uv - 0.5;
    float r = dot(p, p);
    // La fórmula de distorsión
    p *= 1.0 + curve * r;
    return p + 0.5;
}

void fragment() {
    vec2 distorted_uv = distort(UV);
    
    // Verificamos si las coordenadas están fuera de los bordes del monitor
    if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Borde negro si se sale de la curva
    } else {
        vec4 monitor_tex = texture(TEXTURE, UV);
        vec4 ui_tex = texture(interface_texture, distorted_uv);
        
        // Mezclamos: botones sobre el monitor
        COLOR = mix(monitor_tex, ui_tex, ui_tex.a);
    }
}