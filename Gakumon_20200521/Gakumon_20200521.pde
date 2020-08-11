// Masahiro Furukawa
// created :  Dec 25, 2019
// modified : Dec 30, 2019
// modified : Mar 25, 2020
//
String copyright = "Pseudo Random Tracking with Mouse Cursor by Masahiro Furukawa / created : Mar 25, 2020";

// References:
// [1] http://www.d-improvement.jp/learning/processing/2010-b/10.html
//
// [2] https://www.gicentre.net/utils/chart
// [2] http://gicentre.org/utils/reference/
//
// [3] http://www.sojamo.de/libraries/controlP5/
// [3] http://aa-deb.hatenablog.com/entry/2016/11/04/230332

// max frequency = fs / 2     i.e. = 30[Hz]
// min frequency = fs/NUM_FFT    i.e. = 60/1024 = 0.05859375 [Hz]

// constant 
static boolean isPow    = false;
static float sec        = 60.0f;      // sampling duration [s]
static float fs         = 60.0f;      // sampling frequency [hz]
static int   NUM_FREQ   = 17;         // number of sigma      //    [1] https://tachilab.org/content/files/publication/review_papers/tachi1995IEEJ-02.pdf
static float NUM_FFT    = 512.0f;    // number of samples for FFT
static float p          = 1.34f;      // [1] https://tachilab.org/content/files/publication/review_papers/tachi1995IEEJ-02.pdf
static float f_0        = fs/NUM_FFT; // [Hz]
static float a_0        = 200.0f;     // scale factor

//f_0 = 0.0326f; // Hz = (1 / 0.03[s]) [Hz] /1024 [FFT samples] by [1] https://tachilab.org/content/files/publication/review_papers/tachi1995IEEJ-02.pdf
//f_0 = (float)fs/(float)NUM_FFT * scaleFactor;   // [Hz]

void setup() 
{  
  frameRate(fs);
  size(1200, 1200);

  ellipseMode(CENTER);
  cursor(CROSS);
}

// Pseudo Random Signal Series, by Tachi
//
// x(t) = sum_{k=1}^{n}{a_0 * p^{-k} * sin(2 * pi * f_0 * p^k * t + phai_k)}
//
// [1] https://tachilab.org/content/files/publication/review_papers/tachi1995IEEJ-02.pdf

float pseudo_random(float t, int rvs)
{
  float x = 0.0;
  for (int k=1 ; k < NUM_FREQ; k++) {
    if (rvs == 0)
      if (isPow) x += pow(p, -k) * sin(2.0f * PI * f_0 * pow(p, k) * t + phai_k[k]);
      else       x += 1.0f/(float)k* sin(2.0f * PI * f_0 * (float)k    * t + phai_k[k]);
    else
      if (isPow) x += pow(p, -k) * sin(2.0f * PI * f_0 * pow(p, k) * t + phai_k[NUM_FREQ-k-1]); // phase reversed
      else       x += 1.0f/(float)k* sin(2.0f * PI * f_0 * (float)k    * t + phai_k[NUM_FREQ-k-1]); // phase reversed
  }
  //println(x);
  return a_0 * x;
}


void keyPressed() 
{
  if ( key != 's' ) 
    return; 


  if (isRecording) {
    writeFile();
    return;
  }

  println("now recording");
  isRecording = true;
  cnt = 0;
}


void draw() 
{
  if (isRecording)
  {
    stat = "NOW RECORDING";
    msg = "Hit 's' to stop & save";
    cnt++;

    if (cnt >= sec * fs) { 
      writeFile();
      return;
    }
  } else {

    stat = "READY : Put your cursor at the center of the white circle.";
    msg="Hit 's' to start and track the while circle with your cursor while 1 minute.";
    cnt = 0;
  }  

  target_x[cnt] =  pseudo_random(float(cnt)/fs, 0) + (float)width/2;
  target_y[cnt] =  pseudo_random(float(cnt)/fs, 0) + (float)height/2 ; 
  //target_x[cnt] =   (float)width/2;
  //target_y[cnt] = -pseudo_random(float(cnt)/fs, 1) + (float)height/2 ; 

  cursor_x[cnt] = (float)mouseX;
  cursor_y[cnt] = (float)mouseY;

  error_x[cnt] = target_x[cnt] - cursor_x[cnt];
  error_y[cnt] = target_y[cnt] - cursor_y[cnt];

  background(0);
  stroke(255);
  fill(255);

  ellipse(target_x[cnt], target_y[cnt], 40.0, 40.0);

  textSize(14); 

  text(copyright, 0, 10);
  text(stat, 0, 30);
  text(msg, 0, 45);

  if (isRecording ) 
  {
    //text(String.format("Remain[min]  %2d / %2d", (min * fs * 60 - startLines) / fs / 60, minuteLength  ), 600, 400);
  } else {
    text(String.format("Wrote  %s", filename), 0, 65);
  }
}

void writeFile()
{      
  isRecording = false;
  isFull      = false;

  // set file name
  filename = nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + nf(hour(), 2) + nf(minute(), 2) + "_f0_" + nf(f_0)+ "_fs_" + nf(fs)+ "_trial_" + nf(trialNo++);

  try {

    // csv file
    PrintWriter output;
    output = createWriter( savePath(filename + "_float.csv") );
    output.println("ms,target_x,target_y,cursor_x,cursor_y,error_x,error_y");

    for (int i = 1; i < sec * fs; i++)
    {
      output.println( float(i)/fs + "," + 
        target_x[i] + "," + 
        target_y[i] + "," + 

        cursor_x[i] + "," + 
        cursor_y[i] + "," + 

        error_x[i] + "," +
        error_y[i]);
    }

    output.flush(); 
    output.close();
  }
  catch(Exception e) {
    e.printStackTrace();
  }
}

static boolean isWin = (System.getProperty("os.name").contains("Win"));

boolean isRecording = false;
boolean isFull      = false;

int trialNo = 1;
int cnt = 0;
String stat, msg;
String filename = "";

float target_x[] = new float[(int)(sec * fs)];
float target_y[] = new float[(int)(sec * fs)];
float cursor_x[] = new float[(int)(sec * fs)];
float cursor_y[] = new float[(int)(sec * fs)];
float error_x[] = new float[(int)(sec * fs)];
float error_y[] = new float[(int)(sec * fs)];
float phai_k[] = {
  5.61454620570732f, 
  3.08988222967169f, 
  1.36100743703328f, 
  5.02630074346522f, 
  4.98279452555356f, 
  4.10560527854193f, 
  1.37619973871193f, 
  5.56107248324459f, 
  1.98667242242494f, 
  4.24070124840669f, 
  0.38852178446837f, 
  4.48896124546451f, 
  1.73784240114308f, 
  2.41929236052902f, 
  1.61063398242388f, 
  0.176634273223966f, 
  5.30959430627941f, 
  2.29723673594831f, 
  0.815383127257598f, 
  2.79518290877183f, 
  5.84907937440695f, 
  3.57136058555378f, 
  2.27691824798308f, 
  5.14925118249039f, 
  1.07868306441781f, 
  5.51079170334229f, 
  4.68470357608041f, 
  0.47874314676533f, 
  6.0978871592453f, 
  1.81803786003639f, 
  6.13215658427076f, 
  4.6830908193744f, 
  0.81500900085413f, 
  1.38220515466306f, 
  3.94092572009766f, 
  0.741241381506457f, 
  2.13340254574368f, 
  2.40262907383498f, 
  1.28297780507073f, 
  4.70382492823502f, 
  6.26633442609505f, 
  5.78494870744927f, 
  1.83193938842915f, 
  4.98955861101206f, 
  3.90809150889604f, 
  2.94485374684889f, 
  2.47678098706912f, 
  3.73343398433765f, 
  4.74044967368535f, 
  1.28633591374193f, 
  2.26355956042547f, 
  0.757782720428643f, 
  2.47315786195379f, 
  4.59603359787325f, 
  0.989804842380438f, 
  0.92117695728104f, 
  5.33059901562902f, 
  2.58499849908232f, 
  0.766807279474057f, 
  2.3079966190536f, 
  6.06218110638138f, 
  6.02134369324393f, 
  1.72221840115893f, 
  1.34722671883329f, 
  5.21394804365172f, 
  3.41482841995885f, 
  1.02976529637725f, 
  3.0963424990264f, 
  6.1346915928648f, 
  6.24866956245181f, 
  3.18461365592306f, 
  4.12305747591963f, 
  5.98405795445164f, 
  2.11178948516387f, 
  4.44376925713956f, 
  0.692249127268897f, 
  3.64764684727999f, 
  3.21783959089853f, 
  0.63457719522276f, 
  3.00587517738039f, 
  5.51639294004438f, 
  4.49060838764776f, 
  3.87822636018484f, 
  2.45348144154417f, 
  6.00823180010415f, 
  5.75147513342058f, 
  0.841673108095384f, 
  2.83828533498754f, 
  1.64164556691461f, 
  2.6835473248116f, 
  3.44777222838485f, 
  3.21115020259847f, 
  0.849655924172677f, 
  5.44715641006311f, 
  0.89210935208272f, 
  6.02182382975123f, 
  0.926532806898806f, 
  0.397706755346339f, 
  4.54191239396703f, 
  3.34524926438233f, 
  5.54507089792931f, 
  0.457547741394005f};
