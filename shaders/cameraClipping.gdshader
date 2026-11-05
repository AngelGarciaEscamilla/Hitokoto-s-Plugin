shader_type spatial;

// Ajusta esta distancia según necesites
uniform float clip_distance = 0.3;
// Color cuando está cerca (opcional)
uniform vec4 near_color : source_color = vec4(1.0, 0.0, 0.0, 0.5);

void fragment() {
    // Calcula distancia a la cámara
    float dist = distance(CAMERA_POSITION_WORLD, NODE_POSITION_WORLD);

    // Si está muy cerca, descarta el píxel o aplica transparencia
    if (dist < clip_distance) {
        // Opción 1: Desaparece completamente
        discard;

        // Opción 2: Transparencia gradual (descomenta para usar)
        // ALPHA = clamp(dist/clip_distance, 0.1, 1.0);
        // ALBEDO = near_color.rgb;
    }
}