#include "NeonArenaNative.h"

namespace neon_arena
{
    float clamp_damage(float damage, float minimum, float maximum)
    {
        if (damage < minimum) return minimum;
        if (damage > maximum) return maximum;
        return damage;
    }
}
