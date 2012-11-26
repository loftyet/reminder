//
//  CustomerInfoViewController.m
//  TempProject
//
//  Created by Liangjun Jiang on 10/26/12.
//  Copyright (c) 2012 Liangjun Jiang. All rights reserved.
//

#import "ItemDetailViewController.h"
#import "CustomTextField.h"
#import "TextFieldTableCell.h"
#import "TextViewTableCell.h"
#import <QuartzCore/QuartzCore.h>
#import "Event.h"

//#import "SSTheme.h"
#define kTextFieldWidth	195.0
#define kTextHeight		34.0

static NSString *kSectionTitleKey = @"sectionTitleKey";
static NSString *kSourceKey = @"sourceKey";
static NSString *kViewKey = @"viewKey";

@interface ItemDetailViewController ()<UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, GooglePlacesConnectionDelegate, UITextViewDelegate>
@property (nonatomic, retain) NSArray *dataSourceArray;
@property (nonatomic, assign) NSUInteger selectedCellIndex;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, strong) TextFieldTableCell *activeCell;
@property (nonatomic, strong) NSDictionary *howDataDictionary;
@property (nonatomic, strong) NSMutableDictionary *selectedDictionary;
@property (nonatomic, strong) NSString *howString;

// Google place related
@property (nonatomic, strong) NSString *searchString;

@end

@implementation ItemDetailViewController
@synthesize selectedCellIndex, isEditing, activeCell;
@synthesize howDataDictionary, selectedDictionary, howString;
@synthesize event;
@synthesize searchString;

@synthesize resultsLoaded;
@synthesize currentLocation;
@synthesize locations;
@synthesize locationsFilterResults;

#pragma mark - Private Method
- (void)onCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Init & View Cycle
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
//    [SSThemeManager customizeTableView:self.tableView];
    // let's make something like
    isEditing = NO;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    self.navigationItem.leftBarButtonItem = cancelItem;
    
    // Set up the how, such as entering/leaving, alert frequency
    NSArray *repeatOptions = @[@"None",@"Every Day",@"Every Week",@"Every 2 Weeks",@"Every Month", @"Every Year"];
    
    NSArray *locationOptions = @[@"Both", @"Arriving", @"Leaving"];
    
    NSArray *priorityOptions = @[@"None", @"Low", @"Med",@"High"];

    NSArray *inAdvanceOptions = @[@"5 Mins", @"15 Mins",@"30 Mins",@"1 Hour", @"2 Hour",@"1 Day"];
    
    howDataDictionary = @{@"repeat":repeatOptions, @"location":locationOptions, @"inAdvance":inAdvanceOptions, @"priority":priorityOptions};
    howString = @"";
    
    event.how = howString;
    
    NSDictionary *temp = @{@"repeat":@"", @"location":@"",@"inAdvance":@"",@"prority":@""};
    selectedDictionary = [NSMutableDictionary dictionaryWithDictionary:temp];
    
    
    // Set up the content
    NSString *question = @"Remind to use coupon when entering Walmart at 5 pm, tomorrow.";
    
    NSLinguisticTaggerOptions options = NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerJoinNames;
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes: [NSLinguisticTagger availableTagSchemesForLanguage:@"en"] options:options];
    tagger.string = question;
    
    // I need a better algorithm for this
    __block NSMutableArray *tagArrays = [NSMutableArray array];
    [tagger enumerateTagsInRange:NSMakeRange(0, [question length]) scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass options:options usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
        NSString *token = [question substringWithRange:tokenRange];
        NSDictionary *dict = @{@"tag":tag, @"token":token};
        [tagArrays addObject:dict];
    }];
    
    NSLog(@"tag array: %@",tagArrays);
    // I know this is stupid
    __block NSUInteger conjunctionIndex = 0;
    __block NSUInteger particleIndex = 0;
    __block NSUInteger prepositionIndex = 0;
    [tagArrays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = (NSDictionary *)obj;
        if ([dict[@"tag"] isEqualToString:@"Particle"]) {
            particleIndex = idx;
        }
        if ([dict[@"tag"] isEqualToString:@"Conjunction"]) {
            conjunctionIndex = idx;
        }
        if ([dict[@"tag"] isEqualToString:@"Preposition"]) {
            prepositionIndex = idx;
        }
        
    }];
//    NSLog(@"par:%d, con:%d,  prep: %d",particleIndex, conjunctionIndex, prepositionIndex);
//
//
    __block NSMutableString *whatString = [NSMutableString string];

    if  (conjunctionIndex - (particleIndex+1) > 0)
    {
        NSRange whatRange = NSMakeRange(particleIndex+1, conjunctionIndex-(particleIndex+ 1));
        NSArray *whatArray = [tagArrays objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:whatRange]];
        
        if (whatArray.count>0) {
            [whatArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [whatString appendString:[NSString stringWithFormat:@"%@ ",((NSDictionary *)obj)[@"token"]]];
            }];
        }
        NSLog(@"what :%@",whatString);
        event.what = whatString;
    }
    
    __block NSMutableString *whereString = [NSMutableString string];
    if (prepositionIndex-(conjunctionIndex+1) > 0) {
        NSRange whereRange = NSMakeRange(conjunctionIndex+1, prepositionIndex-(conjunctionIndex+ 1));
        NSArray *whereArray = [tagArrays objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:whereRange]];
        if (whereArray.count>0) {
            [whereArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [whereString appendString:[NSString stringWithFormat:@"%@ ",((NSDictionary *)obj)[@"token"]]];
            }];
        }
        NSLog(@"where :%@",whereString);
        event.where = whereString;
    }
    
    __block NSMutableString *whenString = [NSMutableString string];
    if (tagArrays.count-(prepositionIndex+1) > 0) {
        NSRange whenRange = NSMakeRange(prepositionIndex+1, tagArrays.count-(prepositionIndex+ 1));
        NSArray *whenArray = [tagArrays objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:whenRange]];
        if (whenArray.count>0) {
            [whenArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [whenString appendString:[NSString stringWithFormat:@"%@ ",((NSDictionary *)obj)[@"token"]]];
            }];
        }
        NSLog(@"when :%@",whenString);
        event.when = whenString;
    }
    
//    __block NSMutableString *howString = [NSMutableString string];

    
//    NSLog(@"what: %@, when: %@, where :%@",what, when, where);
    self.dataSourceArray = @[@{kSectionTitleKey: @"Summary",
                             kSourceKey: event.name,
                             kViewKey: @(UIKeyboardTypeDefault)},
							
							@{kSectionTitleKey: @"When",
                             kSourceKey: event.when,
                             kViewKey: @(UIKeyboardTypeNamePhonePad)},
							
							@{kSectionTitleKey: @"Where",
                             kSourceKey: event.where,
                             kViewKey: @(UIKeyboardTypePhonePad)},
						    
                            @{kSectionTitleKey: @"What",
                             kSourceKey: event.what,
                             kViewKey: @(UIKeyboardTypeDefault)},
                            
                            @{kSectionTitleKey: @"How",
                             kSourceKey: event.how,
                             kViewKey: @(UIKeyboardTypeDefault)}];
	
	self.title = NSLocalizedString(@"Event Detail", @"Event Detail");
	
	// we aren't editing any fields yet, it will be in edit when the user touches an edit field
	self.editing = NO;
    
    // Location related
    googlePlacesConnection = [[GooglePlacesConnection alloc] initWithDelegate:self];
    
//    
//    [self searchLocationAddress:event.where];
    
    [self searchLocationAddress:@"starbucks"];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    selectedCellIndex = 0;
    
    isEditing = editing;
    [self.tableView reloadData];
    
    // we now need to save those data
    if (!editing) {
        isEditing = editing;
        NSArray *cells = [self.tableView visibleCells];
        [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
        }];
        
        [self.tableView reloadData];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onCheckButton:(id)sender
{
    NSLog(@"we save the user info");
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0)? 100.0: 60.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.dataSourceArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
//    return [self.dataSourceArray count];
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    UITableViewCell *cell;
    NSString *title = self.dataSourceArray[section][kSectionTitleKey];
    NSString *descTitle = self.dataSourceArray[section][kSourceKey];
    NSNumber *keyboardType = self.dataSourceArray[section][kViewKey];
    
    static NSString *kCellSummary = @"CellSummary";
    static NSString *kCellTextField_ID = @"CellTextField_ID";    
    if (section == 0) {
        TextViewTableCell *temp = [tableView dequeueReusableCellWithIdentifier:kCellSummary];
        if (temp == nil) {
            temp = [[TextViewTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellSummary];
        }
        [temp setContentForTableCellLabel:title andTextView:descTitle andKeyBoardType:keyboardType andEnabled:isEditing];
        cell = temp;
    } else {
        TextFieldTableCell *temp = (TextFieldTableCell*) [tableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
        
        if (temp == nil)
        {
            temp = [[TextFieldTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:kCellTextField_ID] ;
            temp.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        temp.textField.delegate = self;
        temp.textField.tag = 100*section + row;
     
        [temp setContentForTableCellLabel:title andTextField:descTitle andKeyBoardType:keyboardType andEnabled:isEditing];
        cell = temp;
    }
    return cell;
}

#pragma mark - Table view delegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
   
    // we row this to top
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // the textfield's super view is TextField Cell
    if ([[textField superview] isKindOfClass:[TextFieldTableCell class]]) {
        TextFieldTableCell *cell = (TextFieldTableCell *)[textField superview];
//        activeIndexPath = [self.tableView indexPathForCell:cell];
        activeCell = cell;
    }
    
    // should this be an independent class?
    UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width, 40)];
    keyboardToolbar.barStyle = UIBarStyleBlackTranslucent;
    keyboardToolbar.tintColor = [UIColor darkGrayColor];
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone:)];
    
    NSArray *itemsArray =  @[doneItem];
    keyboardToolbar.items = itemsArray;
    textField.inputAccessoryView = keyboardToolbar;
    
    if (textField.tag == 100){
        UIDatePicker *datePickerView = [[UIDatePicker alloc] initWithFrame:CGRectZero];
        datePickerView = [[UIDatePicker alloc] initWithFrame:CGRectZero];
        datePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        datePickerView.datePickerMode = UIDatePickerModeDate;
       
        [datePickerView addTarget:self
                           action:@selector(onDatePicker:)
                 forControlEvents:UIControlEventValueChanged];
        
        // this animiation was from Apple Sample Code: DateCell
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGSize pickerSize = [datePickerView sizeThatFits:CGSizeZero];
		CGRect startRect = CGRectMake(0.0,
									  screenRect.origin.y + screenRect.size.height,
									  pickerSize.width, pickerSize.height);
		datePickerView.frame = startRect;
		
      	// compute the end frame
		CGRect pickerRect = CGRectMake(0.0,
									   screenRect.origin.y + screenRect.size.height - pickerSize.height,
									   pickerSize.width,
									   pickerSize.height);
        
        // this animiation will leave the Toolbar alone, so I take it out for the timebeing
        datePickerView.frame = pickerRect;
        
        //        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        //        df.dateStyle = NSDateFormatterMediumStyle;
        //        textField.text = [NSString stringWithFormat:@"%@",[df stringFromDate:datePickerView.date]];
        textField.inputView = datePickerView;
    } else if (textField.tag == 200)  // the user is going to choose from location
    {
        
        NSLog(@"this is for where");
        
        
    } else if (textField.tag == 400)
    {
        UIPickerView *howPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
        howPicker.showsSelectionIndicator = YES;	// note this is default to NO
        howPicker.tag = 101;
        
        // this view controller is the data source and delegate
        howPicker.delegate = self;
        howPicker.dataSource = self;
        [howPicker setExclusiveTouch:YES];
        
        // this animiation was from Apple Sample Code: DateCell
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
        CGSize pickerSize = [howPicker sizeThatFits:CGSizeZero];
        CGRect startRect = CGRectMake(0.0,
                                      screenRect.origin.y + screenRect.size.height,
                                      pickerSize.width, pickerSize.height);
        howPicker.frame = startRect;
        
        // compute the end frame
        CGRect pickerRect = CGRectMake(0.0,
                                       screenRect.origin.y + screenRect.size.height - pickerSize.height,
                                       pickerSize.width,
                                       pickerSize.height);
        
        // For same reason, we take this animiation out
        howPicker.frame = pickerRect;
        
        // attached this picker to textField
        textField.inputView = howPicker;
        
    }
    
    
    return YES;
    
}

#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// the user pressed the "Done" button, so dismiss the keyboard
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    return YES;
}

#pragma mark - UIBarButton Item
- (void)onDone:(id)sender
{
    NSArray *visiableCells = [self.tableView visibleCells];
    [visiableCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[TextFieldTableCell class]]) {
            TextFieldTableCell *cell = (TextFieldTableCell *)obj;
            [cell.textField resignFirstResponder];
        }
        
    }];
}


#pragma mark - Data Picker
- (void)onDatePicker:(id)sender
{
    // We need to create a thread safe data picker
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    
    UIDatePicker *datePicker = (UIDatePicker *)sender;
    activeCell.textField.text = [NSString stringWithFormat:@"%@",[dateFormat stringFromDate:datePicker.date]];
    
}


#pragma mark - how picker delegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *key = [howDataDictionary allKeys][component];
    NSString *selected = ((NSArray *)howDataDictionary[key])[row];
    if (pickerView.tag == 101) {
        
        switch (component) {
            case 0:
            {
                [selectedDictionary setValue:selected forKey:@"inAdvance"];
                break;
            }
            case 1:
            {
                [selectedDictionary setValue:selected forKey:@"repeat"];
                break;
            }
            case 2:
            {
                [selectedDictionary setValue:selected forKey:@"location"];
                break;
            }
            case 3:
            {
                [selectedDictionary setValue:selected forKey:@"priority"];
                break;
            }
            default:
                break;
        }
    }
    
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
    if ([cell isKindOfClass:[TextFieldTableCell class]]) {
        ((TextFieldTableCell *)cell).textField.text = [NSString stringWithFormat:@"%@", selectedDictionary];;
    }
}


#pragma mark -
#pragma mark UIPickerViewDataSource
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:14],  NSForegroundColorAttributeName:[UIColor redColor]};
    
    NSString *returnStr = @"";
    if (pickerView.tag == 101) {
        NSString *key = [howDataDictionary allKeys][component];
        returnStr = ((NSArray *)howDataDictionary[key])[row];
    }
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:returnStr attributes:attributes];
    return string;
    
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *returnStr = @"";
    if (pickerView.tag == 101) {
        NSString *key = [howDataDictionary allKeys][component];
        return ((NSArray *)howDataDictionary[key])[row];
    }
    
	return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	CGFloat componentWidth = 0.0;
    if  (pickerView.tag == 101){
        switch (component) {
            case 0:
                componentWidth = 80.0;
                break;
            case 1:
                componentWidth = 80.0;
                break;
            case 2:
                componentWidth = 60.0;
                break;
            case 3:
                componentWidth = 70.0;
                break;
            default:
                break;
        }
        
        
    }
    return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSString *key = [howDataDictionary allKeys][component];
    
    return ((NSArray *)howDataDictionary[key]).count;
 
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return (pickerView.tag == 101)?4:1;
}


#pragma mark - Google Place Search
- (void)searchLocationAddress:(NSString*)businessName
{
    //What places to search for
    NSString *searchLocations = [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@",
                                 kBar,
                                 kRestaurant,
                                 kCafe,
                                 kBakery,
                                 kFood,
                                 kLodging,
                                 kMealDelivery,
                                 kMealTakeaway,
                                 kNightClub
                                 ];
    CLLocationCoordinate2D here = CLLocationCoordinate2DMake([event.latitude doubleValue], [event.longitude doubleValue]);
    
    [googlePlacesConnection getGoogleObjectsWithQuery:businessName
                                       andCoordinates:here
                                             andTypes:searchLocations];
}


//NEW - to handle filtering
//Create an array by applying the search string

- (void) buildSearchArrayFrom: (NSString *) matchString
{
	NSString *upString = [matchString uppercaseString];
	
	locationsFilterResults = [[NSMutableArray alloc] init];
    
	for (GooglePlacesObject *location in locations)
	{
		if ([matchString length] == 0)
		{
			[locationsFilterResults addObject:location];
			continue;
		}
		
		NSRange range = [[location.name uppercaseString] rangeOfString:upString];
		
        if (range.location != NSNotFound)
        {
            NSLog(@"Hit");
            
            NSLog(@"Location Name %@", location.name);
            NSLog(@"Search String %@", upString);
            
            [locationsFilterResults addObject:location];
        }
	}
}

#pragma mark - Google Place Delegate Method

- (void)googlePlacesConnection:(GooglePlacesConnection *)conn didFinishLoadingWithGooglePlacesObjects:(NSMutableArray *)objects
{
    
    if ([objects count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No matches found near this location"
                                                        message:@"Try another place name or address"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    } else {

        locations = objects;
//        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            GooglePlacesObject *googlePlace = (GooglePlacesObject*)obj;
//            NSLog(@"the address: %@, ",googlePlace.vicinity);
//           
//        }];
    }
}

- (void) googlePlacesConnection:(GooglePlacesConnection *)conn didFailWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error finding place - Try again"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

@end
