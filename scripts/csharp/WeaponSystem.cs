using Godot;

// Optional Godot .NET layer for v5.
// The base project does not depend on this file, so standard Godot remains runnable.
public partial class WeaponSystem : Node
{
    [Export] public int MagazineSize { get; set; } = 30;
    [Export] public float Damage { get; set; } = 20.0f;
    [Export] public float FireRate { get; set; } = 8.0f;

    public bool CanFire(int ammo, float cooldown)
    {
        return ammo > 0 && cooldown <= 0.0f;
    }
}
