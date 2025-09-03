# Budget Management System - User Guide

## Overview
The Budget Management System now includes comprehensive features for managing budget categories, subcategories, and tracking expenses. This system allows government officials to efficiently manage and monitor budget allocations and spending.

## Features

### 1. File Upload Functionality
- **Supported Formats**: CSV (.csv) and Excel (.xlsx, .xls) files
- **Required Columns**:
  - Column A: Category Name (required)
  - Column B: Description (optional)
  - Column C: Allocated Amount (required, numeric)
  - Column D: Spent Amount (optional, numeric, defaults to 0)
- **First Row**: Should contain headers
- **Data Validation**: Automatically validates amounts and skips invalid rows

### 2. Budget Categories Management
- **Create**: Add new budget categories with custom names, descriptions, amounts, and colors
- **Edit**: Modify existing category details including name, description, allocated amount, and color
- **Delete**: Remove categories (with confirmation dialog)
- **View**: See all categories with visual indicators and progress bars

### 3. Subcategories Support
- **Add Subcategories**: Create detailed breakdowns within main categories
- **Manage Subcategories**: Edit names, descriptions, and allocated amounts
- **Hierarchical Structure**: Organize budgets in a logical hierarchy

### 4. Expense Tracking
- **Add Expenses**: Record actual spending against budget categories
- **Budget Validation**: Prevents adding expenses that exceed remaining budget
- **Real-time Updates**: Automatically updates utilization percentages and remaining amounts

### 5. Analytics and Reporting
- **Summary Cards**: Total budget, spent amount, remaining budget, and utilization percentage
- **Progress Bars**: Visual representation of budget utilization
- **Color Coding**: Different colors for different budget statuses

## How to Use

### File Upload Process
1. **Prepare Your File**: Ensure your CSV or Excel file follows the required format
2. **Select File**: Click "Browse Files" to choose your CSV or Excel file
3. **Upload**: Click "Upload" to process the file
4. **Review**: Check the processed categories before saving
5. **Save**: Click "Save All" to store categories in the system

### Managing Categories
1. **Navigate**: Go to "View All Budgets" from the main upload screen
2. **Actions Menu**: Use the three-dot menu on each category card for:
   - Edit category details
   - Add subcategories
   - Add expenses
   - Delete category
3. **Real-time Updates**: All changes are immediately reflected in the system

### Adding Expenses
1. **Select Category**: Choose the category from the management screen
2. **Add Expense**: Use the "Add Expense" option from the actions menu
3. **Enter Details**: Provide description and amount
4. **Validation**: System checks if expense exceeds remaining budget
5. **Confirmation**: Expense is added and budget is updated

## File Format Examples

### Excel Format
```
| Category Name           | Description                    | Allocated Amount |
|------------------------|--------------------------------|------------------|
| Infrastructure         | Roads and bridges              | 50000000        |
| Healthcare            | Medical facilities             | 30000000        |
| Education             | Schools and programs           | 25000000        |
```

### CSV Format
```csv
Category Name,Description,Allocated Amount,Spent Amount
Infrastructure,Roads and bridges,50000000,35000000
Healthcare,Medical facilities,30000000,28000000
Education,Schools and programs,25000000,12000000
```

## Troubleshooting

### File Upload Issues
- **File Not Selected**: Ensure you've selected a file before clicking upload
- **Format Errors**: Check that your file follows the required column structure
- **Empty Rows**: The system automatically skips rows with missing data
- **Invalid Amounts**: Ensure amounts are numeric values

### Common Problems
- **File Size**: Large files may take longer to process
- **Network Issues**: Check your internet connection for upload problems
- **Browser Compatibility**: Use modern browsers for best results

## Best Practices

### Data Preparation
1. **Clean Data**: Remove empty rows and ensure consistent formatting
2. **Validate Amounts**: Double-check all monetary values
3. **Use Descriptions**: Add meaningful descriptions for better organization
4. **Test Upload**: Try with a small file first to verify format

### Budget Management
1. **Regular Updates**: Update expenses regularly for accurate tracking
2. **Monitor Utilization**: Keep track of spending against allocations
3. **Use Subcategories**: Break down large categories for better control
4. **Review Reports**: Regularly check analytics for insights

## Technical Notes

### Supported File Types
- CSV (.csv) - Primary format with robust parsing
- Excel (.xlsx, .xls) - Legacy support maintained

### Data Validation
- Category names are required and trimmed
- Amounts must be positive numbers
- Descriptions are optional
- Invalid rows are automatically skipped

### Performance
- Files are processed client-side for better performance
- Large files may take several seconds to process
- Progress indicators show upload status

## Support

If you encounter issues:
1. Check the console logs for error messages
2. Verify your file format matches the requirements
3. Ensure all required fields are filled
4. Try with a smaller test file first

For additional support, contact your system administrator or technical team.
