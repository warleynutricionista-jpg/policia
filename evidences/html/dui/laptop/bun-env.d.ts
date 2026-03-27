declare module "*.png" {
  /**
   * A path to the PNG file
   */
  const path: `${string}.png`;
  export = path;
}

declare module "*.mp3" {
  /**
   * A path to the MP3 file
   */
  const path: `${string}.mp3`;
  export = path;
}


declare module "*.module.css" {
  /**
   * A record of class names to their corresponding CSS module classes
   */
  const classes: { readonly [key: string]: string };
  export = classes;
}
