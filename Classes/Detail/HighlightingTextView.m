
/*
     File: HighlightingTextView.m
 Abstract: A text view that provides support for highlighting by changing the text color.
 
  Version: 2.0
 
 Copyright (C) 2011 LJApps. All Rights Reserved.
 
 */

#import "HighlightingTextView.h"


@implementation HighlightingTextView

@synthesize highlighted;


-(void)setHighlighted:(BOOL)highlight; {
    
    // Adjust the text color based on highlighted state.
    if (highlight != highlighted) {
        self.textColor = highlight ? [UIColor whiteColor] : [UIColor blackColor];
        highlighted = highlight;
    }
}


@end
