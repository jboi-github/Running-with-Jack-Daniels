# Running with Jack Daniels
Collection of functions to calculate running velocities and training calendar according to Jack Daniels Running Formula.

Jack Daniels did many things in sports as you can check out on [Wikipedia](https://en.wikipedia.org/wiki/Jack_Daniels_(coach))
He especially founded a way to measure running success and build your trainings plans, trackings and even setbacks after breaks around one simple indicator: VDOT

Tables exist, mainly taken from the book [Jack Daniels Running Formula](https://books.google.de/books/about/Daniels_Running_Formula.html?id=ovN6DwAAQBAJ&source=kp_book_description&redir_esc=y), that can tell you your VDOT and let you choose your training valocities. One out of many good examples is this one from [Carsten Schulz](https://carsten.codimi.de/daniels.html) which also contains a calculator.

Reading the book you realize, that Jack has given us detailed material to calculate for all steps of a runners season. No matter if you just started or if you're a very experienced runner. If you want to take it serious, if you like to measure your success, VDOT is the performance indicator to go.

## Content
This repository contains a set of back-end functions to calculate all necesary results along the four areas of setting the goal and knowing your status quo, plan your season, track your workouts and adjust when it gets possible (raise) or necessary (lower intensity).

The four areas come along three levels of precision:
1. Macrolevel, that defines a season, their goals like some particular race or fitness improvements and planned breaks.
2. Midilevel, which lays out a plan for each week. How to mix Quality trainings and recovery days into your weekly schedule.
3. Microlevel, or what happens in each single workout. 

Every area at each level has its own data, which can be input-, output or calculated data:

|| Macrolevel (Season) | Midilevel (Week) | Microlevel (Workout) |
| --- | --- | --- | --- |
| Status Quo | Planned breaks, vacation | Constraints per week, preferred training-days, - times, -durations, -distances | Current vdot, HRmax, BMI |
| Goal | Race/competition or fitness improvement?<br>- Race: Distance, date<br>- Fitness: Distance, duration at end of season |
| Plan | Phases over weeks | Workouts: weekday, durations, Quality vs easy, workout-duration | Intensities (order, duration, speed) |
| Track | Trends:<br>- estimated vdot | Points:<br>- The more intensity, the more points<br>The longer, the more points<br>- 70% minimum E is must | vdot estimation:<br>- HR% = HR / HRmax<br>- vdot% = table(HR%)<br>- vdot = table(speed, intensity)<br>- vdot% compared to vdot<br>How do you feel today? (Before)<br>How did you make it? (After) |
| Adjust | AdHoc-replanning along fulfillments along plan | AdHoc-replanning along past feelings, gaps (setback), fulfillments along plan | AdHoc-replanning along todays feeling, estimated vdot in last workouts |

## Two inputs and a dynamic output

## Areas

![alt text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png "Logo Title Text 1")
