import matplotlib.pyplot as plt

def dynamic_range(vol):
    if vol < 10:
        return 3
    elif vol < 30:
        return 6
    else:
        return 12

def main():
    vols = list(range(0, 61))
    ranges = [dynamic_range(v) for v in vols]

    plt.figure()
    plt.step(vols, ranges, where="post")
    plt.xlabel("Volatility (|tick - twap|)")
    plt.ylabel("Central range R (ticks)")
    plt.title("AutoRange Tri-Pillar dynamic central range")
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
