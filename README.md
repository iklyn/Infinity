# Infinity

A small timer that lives in your Mac's menu bar.

## Why I made this

A lot of apps charge you for simple things a computer should just do — a timer, a countdown, a clock. Some of them want a monthly subscription for it. I got tired of paying for the basics, so I made my own.

It's free. No subscription, no paywall, no account, no ads. If it's useful to you, keep it.

I also wanted it to be nice to look at, since I'd be glancing at it every day.

## What it does

Click the infinity icon in your menu bar and it opens. You can keep three kinds of things in it:

- **Timer** — a normal countdown for minutes or hours. When it hits zero, it plays a sound until you stop it. Good for tea, laundry, a quick break.
- **Date** — pick a date. If it's in the future, it counts down to it ("211 days to go"). If it's in the past, it counts up from it ("31 years"). So it works for both a deadline and a birthday.
- **Progress** — pick a start and an end, and it shows how far along you are as a percentage. Like how much of the year is gone.

It handles anything from a few seconds up to the year 2099.

A few small things it does to stay out of your way:

- It saves everything, so your timers are still there after you restart.
- It has no Dock icon and no pop-up notifications — it just sits in the menu bar.
- You can name a timer or leave it blank.
- The alarm stops when you press Esc, click Stop, or click the menu bar icon.

## Running it

You need a Mac with Apple's command-line tools installed. Then:

```bash
bash scripts/build.sh   # build it
bash scripts/run.sh     # open it
```

The infinity icon shows up in your menu bar. That's it.

## Made by

Kalyan — [kalyanaslog1@gmail.com](mailto:kalyanaslog1@gmail.com)
