onPressed: () {
  // TODO: Navigate to checkout screen
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Checkout functionality coming soon!'),
      backgroundColor: AppColors.primary,
    ),
  );
},