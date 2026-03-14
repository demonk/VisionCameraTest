//
//  ChatViewController.m
//  test
//

#import "ChatViewController.h"

@interface ChatViewController () <UIScrollViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIScrollView *chatScrollView;
@property (nonatomic, strong) UIView *chatContainerView;
@property (nonatomic, strong) UIView *bottomContainerView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UITextView *messageInputView;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSArray *randomResponses;
@property (nonatomic, strong) UIView *gradientBackgroundView;

@end

// UITextView category for placeholder text
@interface UITextView (Placeholder)
- (void)setText:(NSString *)text color:(UIColor *)color;
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.messages = [NSMutableArray array];
    self.randomResponses = @[
        @"That's interesting! Tell me more.",
        @"I see what you mean. Go on!",
        @"Hmm, let me think about that...",
        @"Oh really? That's fascinating!",
        @"I'm not sure I understand. Can you explain?",
        @"That makes sense to me!",
        @"Wow, I didn't know that!",
        @"Interesting point! What else?",
        @"I agree with you on that.",
        @"Hmm, I have a different perspective.",
        @"Thanks for sharing that with me!",
        @"That's a great question!",
        @"Let me ponder on that for a moment...",
        @"You make a good point there!",
        @"I'm curious to know more about this."
    ];

    [self setupGradientBackground];
    [self setupBackButton];
    [self setupBottomSection];
    [self setupChatScrollView];

    // Add initial messages
    [self addMessage:@"Hi there! Welcome to the chat! 👋" isUser:NO];
    [self addMessage:@"Hello! Nice to meet you!" isUser:YES];
    [self addMessage:@"What brings you here today?" isUser:NO];

    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Update gradient frame
    self.gradientBackgroundView.frame = self.view.bounds;

    // Update scroll view and layout messages
    [self layoutChatMessages];
}

#pragma mark - Setup Methods

- (void)setupBackButton {
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
    self.backButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.backButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [self.backButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.backButton.heightAnchor constraintEqualToConstant:30]
    ]];
}

- (void)setupGradientBackground {
    self.gradientBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];

    // Create gradient layer with soft pink/mauve colors
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.92 green:0.82 blue:0.86 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.76 green:0.66 blue:0.72 alpha:1.0].CGColor
    ];
    gradientLayer.locations = @[@0.0, @1.0];
    gradientLayer.startPoint = CGPointMake(0.0, 0.0);
    gradientLayer.endPoint = CGPointMake(1.0, 1.0);

    [self.gradientBackgroundView.layer addSublayer:gradientLayer];
    [self.view insertSubview:self.gradientBackgroundView atIndex:0];
}

- (void)setupChatScrollView {
    self.chatScrollView = [[UIScrollView alloc] init];
    self.chatScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.chatScrollView.showsVerticalScrollIndicator = NO;
    self.chatScrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.chatScrollView.delegate = self;
    [self.view addSubview:self.chatScrollView];

    self.chatContainerView = [[UIView alloc] init];
    self.chatContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.chatScrollView addSubview:self.chatContainerView];

    [NSLayoutConstraint activateConstraints:@[
        [self.chatScrollView.topAnchor constraintEqualToAnchor:self.backButton.bottomAnchor constant:10],
        [self.chatScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.chatScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.chatScrollView.bottomAnchor constraintEqualToAnchor:self.bottomContainerView.topAnchor],

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
    self.bottomContainerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.bottomContainerView];

    // Input text view
    self.messageInputView = [[UITextView alloc] init];
    self.messageInputView.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageInputView.font = [UIFont systemFontOfSize:16];
    self.messageInputView.backgroundColor = [UIColor whiteColor];
    self.messageInputView.textColor = [UIColor darkTextColor];
    self.messageInputView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.messageInputView.layer.borderWidth = 1.0;
    self.messageInputView.layer.cornerRadius = 20;
    self.messageInputView.textContainerInset = UIEdgeInsetsMake(8, 12, 8, 12);
    self.messageInputView.delegate = self;
    self.messageInputView.scrollEnabled = NO;
    [self.messageInputView setText:@"Message..." color:[UIColor lightGrayColor]];
    [self.bottomContainerView addSubview:self.messageInputView];

    // Send button
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.sendButton.backgroundColor = [UIColor colorWithRed:0.25 green:0.5 blue:0.9 alpha:1.0];
    self.sendButton.layer.cornerRadius = 20;
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainerView addSubview:self.sendButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.messageInputView.topAnchor constraintEqualToAnchor:self.bottomContainerView.topAnchor constant:12],
        [self.messageInputView.leadingAnchor constraintEqualToAnchor:self.bottomContainerView.leadingAnchor constant:12],
        [self.messageInputView.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-8],
        [self.messageInputView.bottomAnchor constraintEqualToAnchor:self.bottomContainerView.bottomAnchor constant:-12],
        [self.messageInputView.heightAnchor constraintLessThanOrEqualToConstant:100],

        [self.sendButton.topAnchor constraintEqualToAnchor:self.messageInputView.topAnchor],
        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.bottomContainerView.trailingAnchor constant:-12],
        [self.sendButton.bottomAnchor constraintEqualToAnchor:self.messageInputView.bottomAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:70]
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [self.bottomContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.bottomContainerView.heightAnchor constraintGreaterThanOrEqualToConstant:60]
    ]];
}

#pragma mark - Chat Messages

- (void)layoutChatMessages {
    // Remove existing message views
    for (UIView *subview in self.chatContainerView.subviews) {
        [subview removeFromSuperview];
    }

    CGFloat margin = 16;
    CGFloat bubblePadding = 12;
    CGFloat maxWidth = self.view.frame.size.width * 0.7;
    CGFloat currentY = margin;

    for (NSDictionary *message in self.messages) {
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
        bubbleView.backgroundColor = isUser ? [UIColor colorWithRed:0.25 green:0.5 blue:0.9 alpha:1.0] : [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
        bubbleView.layer.cornerRadius = 16;

        // Set masked corners for rounded effect
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
        label.preferredMaxLayoutWidth = maxWidth - bubblePadding * 2;
        label.frame = CGRectMake(bubblePadding, bubblePadding, textSize.width, textSize.height);
        [bubbleView addSubview:label];

        // Position bubble
        CGFloat x = isUser ? self.view.frame.size.width - bubbleWidth - margin : margin;
        bubbleView.frame = CGRectMake(x, currentY, bubbleWidth, bubbleHeight);

        [self.chatContainerView addSubview:bubbleView];

        currentY += bubbleHeight + 8;
    }

    self.chatContainerView.frame = CGRectMake(0, 0, self.view.frame.size.width, currentY);

    // Scroll to bottom
    CGFloat contentHeight = self.chatContainerView.frame.size.height;
    CGFloat visibleHeight = self.chatScrollView.frame.size.height;
    if (contentHeight > visibleHeight) {
        CGPoint offset = CGPointMake(0, contentHeight - visibleHeight);
        [self.chatScrollView setContentOffset:offset animated:NO];
    }
}

- (void)addMessage:(NSString *)text isUser:(BOOL)isUser {
    [self.messages addObject:@{@"text": text, @"isUser": @(isUser)}];
    [self layoutChatMessages];
}

- (void)sendMessage {
    NSString *messageText = self.messageInputView.text;

    // Check if placeholder text
    if ([messageText isEqualToString:@"Message..."] || [messageText isEqualToString:@""]) {
        return;
    }

    // Add user message
    [self addMessage:messageText isUser:YES];
    [self scrollToBottom];

    // Clear input
    self.messageInputView.text = @"";
    [self.messageInputView setText:@"Message..." color:[UIColor lightGrayColor]];
    [self.messageInputView resignFirstResponder];

    // Simulate opponent response after delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self simulateOpponentResponse];
    });
}

- (void)simulateOpponentResponse {
    // Get random response
    NSUInteger index = arc4random_uniform((uint32_t)self.randomResponses.count);
    NSString *response = self.randomResponses[index];

    [self addMessage:response isUser:NO];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@"Message..."]) {
        textView.text = @"";
        textView.textColor = [UIColor darkTextColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        [textView setText:@"Message..." color:[UIColor lightGrayColor]];
    }
}

#pragma mark - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat keyboardHeight = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    // Adjust scroll view content inset to account for keyboard
    UIEdgeInsets contentInset = self.chatScrollView.contentInset;
    contentInset.bottom = keyboardHeight;

    [UIView animateWithDuration:duration animations:^{
        self.chatScrollView.contentInset = contentInset;
        self.chatScrollView.scrollIndicatorInsets = contentInset;
    }];

    // Scroll to bottom after keyboard shows
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollToBottom];
    });
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration animations:^{
        self.chatScrollView.contentInset = UIEdgeInsetsZero;
        self.chatScrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

- (void)scrollToBottom {
    CGFloat contentHeight = self.chatContainerView.frame.size.height;
    CGFloat visibleHeight = self.chatScrollView.frame.size.height;
    if (contentHeight > visibleHeight) {
        CGPoint offset = CGPointMake(0, contentHeight - visibleHeight);
        [self.chatScrollView setContentOffset:offset animated:YES];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Can add additional scroll handling here if needed
}

#pragma mark - Actions

- (void)backButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// UITextView category for placeholder
@implementation UITextView (Placeholder)

- (void)setText:(NSString *)text color:(UIColor *)color {
    self.text = text;
    self.textColor = color;
}

@end
