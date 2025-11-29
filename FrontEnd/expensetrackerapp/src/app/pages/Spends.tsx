import React, { useState, useEffect } from 'react';
import { View, StyleSheet } from 'react-native';
import Heading from '../components/Heading';
import Expense from '../components/Expense';
import CustomBox from '../components/CustomBox';
import CustomText from '../components/CustomText';
import {ExpenseDto} from '../pages/dto/ExpenseDto';
import ApiService from '../api/ApiService';

const Spends = () => {
  const [expenses, setExpenses] = useState<ExpenseDto[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchExpenses();
  }, []);

  const fetchExpenses = async () => {
    try {
      const response = await ApiService.getExpenses();

      if (response.error) {
        setError(response.error);
        setIsLoading(false);
        return;
      }

      if (response.data) {
        const transformedExpenses: ExpenseDto[] = response.data.map((expense: any, index: number) => ({
          key: index + 1,
          amount: typeof expense.amount === 'string' ? parseFloat(expense.amount) : expense.amount,
          merchant: expense.merchant || 'Unknown',
          currency: expense.currency || 'INR',
          createdAt: expense.created_at ? new Date(expense.created_at) : new Date(),
        }));

        setExpenses(transformedExpenses);
        setError(null);
      } else {
        setExpenses([]);
      }
      setIsLoading(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
      console.error('Error fetching expenses:', err);
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <View>
        <Heading props={{ heading: 'spends' }} />
        <CustomBox style={headingBox}>
          <CustomText style={{}}>Loading expenses...</CustomText>
        </CustomBox>
      </View>
    );
  }

  if (error) {
    return (
      <View>
        <Heading props={{ heading: 'spends' }} />
        <CustomBox style={headingBox}>
          <CustomText style={{}}>Error: {error}</CustomText>
        </CustomBox>
      </View>
    );
  }

  return (
    <View>
      <Heading
        props={{
          heading: 'spends',
        }}
      />
      <CustomBox style={headingBox}>
        <View style={styles.expenses}>
          {expenses.map(expense => (
            <Expense key={expense.key} props={expense} />
          ))}
        </View>
      </CustomBox>
    </View>
  );
};

export default Spends;

const styles = StyleSheet.create({
  expenses: {
    marginTop: 20,
  },
});

const headingBox = {
  mainBox: {
    backgroundColor: 'white',
    borderColor: 'black',
  },
  shadowBox: {
    backgroundColor: 'gray',
  },
  styles: {
    marginTop: 20,
  },
};