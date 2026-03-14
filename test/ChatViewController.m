//
//  ChatViewController.m
//  test
//

#import "ChatViewController.h"

@interface ChatViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *chatScrollView;
@property (nonatomic, strong) UIView *chatContainerView;
@property (nonatomic, strong) UIView *bottomContainerView;
@property (nonatomic, strong) UIView *gradientBackgroundView;
@property (nonatomic, strong) UILabel *statusBadge;
@property (nonatomic, strong) NSArray *suggestionButtons;
@property (nonatomic, strong) UIButton *callButton;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupGradientBackground];
    [self setupStatusBadge];
    [self setupChatScrollView];
    [self setupBottomSection];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Update gradient frame
    self.gradientBackgroundView.frame = self.view.bounds;

    // Layout chat bubbles
    [self layoutChatMessages];

    // Update scroll view content size
    CGFloat bottomHeight = 220;
    CGFloat contentHeight = self.chatContainerView.frame.size.height;
    self.chatScrollView.contentSize = CGSizeMake(self.view.frame.size.width, contentHeight + bottomHeight);
}

#pragma mark - Setup Methods

- (void)setupGradientBackground {
    self.gradientBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];

    // Create gradient layer with soft pink/mauve colors
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.92 green:0.82 blue:0.86 alpha:1.0].CGColor,  // Soft pink
        (__bridge id)[UIColor colorWithRed:0.76 green:0.66 blue:0.72 alpha:1.0].CGColor   // Mauve
    ];
    gradientLayer.locations = @[@0.0, @1.0];
    gradientLayer.startPoint = CGPointMake(0.0, 0.0);
    gradientLayer.endPoint = CGPointMake(1.0, 1.0);

    [self.gradientBackgroundView.layer addSublayer:gradientLayer];
    [self.view addSubview:self.gradientBackgroundView];
}

- (void)setupStatusBadge {
    self.statusBadge = [[UILabel alloc] init];
    self.statusBadge.text = @"Ready";
    self.statusBadge.textColor = [UIColor whiteColor];
    self.statusBadge.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.statusBadge.textAlignment = NSTextAlignmentCenter;
    self.statusBadge.backgroundColor = [UIColor colorWithRed:0.3 green:0.75 blue:0.4 alpha:1.0];
    self.statusBadge.layer.cornerRadius = 12;
    self.statusBadge.layer.masksToBounds = YES;
    self.statusBadge.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.statusBadge];

    [NSLayoutConstraint activateConstraints:@[
        [self.statusBadge.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [self.statusBadge.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.statusBadge.widthAnchor constraintEqualToConstant:60],
        [self.statusBadge.heightAnchor constraintEqualToConstant:24]
    ]];
}

- (void)setupChatScrollView {
    self.chatScrollView = [[UIScrollView alloc] init];
    self.chatScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.chatScrollView.showsVerticalScrollIndicator = NO;
    self.chatScrollView.delegate = self;
    [self.view addSubview:self.chatScrollView];

    self.chatContainerView = [[UIView alloc] init];
    self.chatContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.chatScrollView addSubview:self.chatContainerView];

    [NSLayoutConstraint activateConstraints:@[
        [self.chatScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.chatScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.chatScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.chatScrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.chatContainerView.topAnchor constraintEqualToAnchor:self.chatScrollView.topAnchor],
        [self.chatContainerView.leadingAnchor constraintEqualToAnchor:self.chatScrollView.leadingAnchor],
        [self.chatContainerView.trailingAnchor constraintEqualToAnchor:self.chatScrollView.trailingAnchor],
        [self.chatContainerView.bottomAnchor constraintEqualToAnchor:self.chatScrollView.bottomAnchor],
        [self.chatContainerView.widthAnchor constraintEqualToAnchor:self.chatScrollView.widthAnchor]
    ]];
}

- (void)setupBottomSection {
    self.bottomContainerView = [[UIView alloc] init];
    self.bottomContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bottomContainerView];

    // "YOU CAN SAY" label
    UILabel *suggestionLabel = [[UILabel alloc] init];
    suggestionLabel.text = @"YOU CAN SAY";
    suggestionLabel.textColor = [UIColor whiteColor];
    suggestionLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    suggestionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bottomContainerView addSubview:suggestionLabel];

    // Suggestion buttons
    NSArray *suggestions = @[
        @"I'm Alex, nice to meet you, Nana!",
        @"My name is Alex, and it's a pleasure to meet you!",
        @"I'm Alex, and I'm happy to chat with you, Nana!"
    ];

    NSMutableArray *buttons = [NSMutableArray array];
    UIButton *lastButton = nil;

    for (NSString *text in suggestions) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:text forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        button.layer.borderColor = [UIColor whiteColor].CGColor;
        button.layer.borderWidth = 1.0;
        button.layer.cornerRadius = 8;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(suggestionTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomContainerView addSubview:button];
        [buttons addObject:button];

        [NSLayoutConstraint activateConstraints:@[
            [button.leadingAnchor constraintEqualToAnchor:self.bottomContainerView.leadingAnchor constant:16],
            [button.trailingAnchor constraintEqualToAnchor:self.bottomContainerView.trailingAnchor constant:-16],
            [button.heightAnchor constraintEqualToConstant:44]
        ]];

        if (lastButton) {
            [button.topAnchor constraintEqualToAnchor:lastButton.bottomAnchor constant:10].active = YES;
        } else {
            [button.topAnchor constraintEqualToAnchor:suggestionLabel.bottomAnchor constant:12].active = YES;
        }

        lastButton = button;
    }

    self.suggestionButtons = buttons;

    // Red circular call button
    self.callButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.callButton.backgroundColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.25 alpha:1.0];
    self.callButton.layer.cornerRadius = 35;
    self.callButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.callButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.callButton.layer.shadowRadius = 8;
    self.callButton.layer.shadowOpacity = 0.3;
    self.callButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.callButton addTarget:self action:@selector(callButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    // Add phone icon
    UIImage *phoneImage = [self phoneIconImage];
    [self.callButton setImage:phoneImage forState:UIControlStateNormal];
    self.callButton.tintColor = [UIColor whiteColor];
    [self.callButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];

    [self.bottomContainerView addSubview:self.callButton];

    [NSLayoutConstraint activateConstraints:@[
        [suggestionLabel.topAnchor constraintEqualToAnchor:self.bottomContainerView.topAnchor constant:8],
        [suggestionLabel.leadingAnchor constraintEqualToAnchor:self.bottomContainerView.leadingAnchor constant:16],

        [self.callButton.topAnchor constraintEqualToAnchor:lastButton.bottomAnchor constant:20],
        [self.callButton.centerXAnchor constraintEqualToAnchor:self.bottomContainerView.centerXAnchor],
        [self.callButton.widthAnchor constraintEqualToConstant:70],
        [self.callButton.heightAnchor constraintEqualToConstant:70],
        [self.callButton.bottomAnchor constraintEqualToAnchor:self.bottomContainerView.bottomAnchor constant:-20]
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [self.bottomContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.bottomContainerView.heightAnchor constraintEqualToConstant:280]
    ]];
}

- (UIImage *)phoneIconImage {
    CGSize size = CGSizeMake(30, 30);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    // Draw phone icon
    UIBezierPath *path = [UIBezierPath bezierPath];

    // Phone handset shape
    [path moveToPoint:CGPointMake(8, 6)];
    [path addCurveToPoint:CGPointMake(4, 10) controlPoint1:CGPointMake(6, 6) controlPoint2:CGPointMake(4, 8)];
    [path addCurveToPoint:CGPointMake(12, 24) controlPoint1:CGPointMake(4, 16) controlPoint2:CGPointMake(8, 20)];
    [path addCurveToPoint:CGPointMake(20, 24) controlPoint1:CGPointMake(14, 22) controlPoint2:CGPointMake(18, 22)];
    [path addCurveToPoint:CGPointMake(24, 20) controlPoint1:CGPointMake(22, 24) controlPoint2:CGPointMake(24, 22)];
    [path addCurveToPoint:CGPointMake(20, 16) controlPoint1:CGPointMake(24, 18) controlPoint2:CGPointMake(22, 16)];
    [path addCurveToPoint:CGPointMake(16, 20) controlPoint1:CGPointMake(18, 16) controlPoint2:CGPointMake(16, 18)];
    [path addCurveToPoint:CGPointMake(12, 16) controlPoint1:CGPointMake(14, 20) controlPoint2:CGPointMake(12, 18)];
    [path addCurveToPoint:CGPointMake(16, 10) controlPoint1:CGPointMake(12, 12) controlPoint2:CGPointMake(14, 10)];
    [path addCurveToPoint:CGPointMake(20, 6) controlPoint1:CGPointMake(18, 10) controlPoint2:CGPointMake(20, 8)];
    [path addCurveToPoint:CGPointMake(8, 6) controlPoint1:CGPointMake(16, 2) controlPoint2:CGPointMake(12, 2)];

    [[UIColor whiteColor] setFill];
    [path fill];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

#pragma mark - Chat Messages

- (void)layoutChatMessages {
    // Remove existing message views
    for (UIView *subview in self.chatContainerView.subviews) {
        [subview removeFromSuperview];
    }

    NSArray *messages = @[
        @{ @"text": @"Hi there! Welcome to the chat! 👋", @"isUser": @NO },
        @{ @"text": @"Hello! Nice to meet you!", @"isUser": @YES },
        @{ @"text": @"What brings you here today?", @"isUser": @NO },
        @{ @"text": @"Just exploring the app. How are you?", @"isUser": @YES },
        @{ @"text": @"I'm doing great, thanks for asking! 😊", @"isUser": @NO },
        @{ @"text": @"That's wonderful to hear!", @"isUser": @YES },
        @{ @"text": @"Hello! How can I help you?", @"isUser": @NO },
        @{ @"text": @"How Are You?", @"isUser": @YES },
        @{ @"text": @"Great, thanks! How 'bout you?", @"isUser": @NO },
        @{ @"text": @"Do you know my name?", @"isUser": @YES },
        @{ @"text": @"Nope. But I'm Nana, and you are?", @"isUser": @NO },
        @{ @"text": @"I'm Alex! Nice to meet you, Nana!", @"isUser": @YES },
        @{ @"text": @"Nice to meet you too, Alex! What can I help you with today?", @"isUser": @NO }
    ];

    CGFloat margin = 16;
    CGFloat bubblePadding = 12;
    CGFloat maxWidth = self.view.frame.size.width * 0.7;
    CGFloat currentY = 60; // Start below status badge

    for (NSDictionary *message in messages) {
        NSString *text = message[@"text"];
        BOOL isUser = [message[@"isUser"] boolValue];

        // Calculate size
        CGSize textSize = [text boundingRectWithSize:CGSizeMake(maxWidth - bubblePadding * 2, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]}
                                             context:nil].size;

        CGFloat bubbleWidth = textSize.width + bubblePadding * 2;
        CGFloat bubbleHeight = textSize.height + bubblePadding * 2;

        // Create bubble
        UIView *bubbleView = [[UIView alloc] init];
        bubbleView.backgroundColor = isUser ? [UIColor colorWithRed:0.35 green:0.6 blue:0.9 alpha:1.0] : [UIColor whiteColor];
        bubbleView.layer.cornerRadius = 16;
        if (isUser) {
            bubbleView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMinYCorner;
        } else {
            bubbleView.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMaxXMaxYCorner | kCALayerMinXMinYCorner;
        }
        bubbleView.layer.masksToBounds = YES;

        UILabel *label = [[UILabel alloc] init];
        label.text = text;
        label.font = [UIFont systemFontOfSize:15];
        label.textColor = isUser ? [UIColor whiteColor] : [UIColor darkTextColor];
        label.numberOfLines = 0;
        label.frame = CGRectMake(bubblePadding, bubblePadding, textSize.width, textSize.height);
        [bubbleView addSubview:label];

        // Position bubble
        CGFloat x = isUser ? self.view.frame.size.width - bubbleWidth - margin : margin;
        bubbleView.frame = CGRectMake(x, currentY, bubbleWidth, bubbleHeight);

        [self.chatContainerView addSubview:bubbleView];

        currentY += bubbleHeight + 12;
    }

    self.chatContainerView.frame = CGRectMake(0, 0, self.view.frame.size.width, currentY);
}

#pragma mark - Actions

- (void)suggestionTapped:(UIButton *)sender {
    NSLog(@"Suggestion tapped: %@", sender.titleLabel.text);
}

- (void)callButtonTapped:(UIButton *)sender {
    NSLog(@"Call button tapped");
}

@end
