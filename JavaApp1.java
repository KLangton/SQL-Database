import java.sql.*;
import java.util.Scanner;

public class JavaApp1 {
	private static final Scanner S = new Scanner(System.in);

	private static Connection c = null;

	public static void main(String[] args) {
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");

			c = DriverManager.getConnection("jdbc:mysql://localhost:3306/coursework?serverTimezone=GMT", "root","Sl@sher567?" ); // ToDo : Specify Parameters !


			String choice = "";

			do {
				System.out.println("-- MAIN MENU --");
				System.out.println("1 - Browse ResultSet");
				System.out.println("2 - Invoke Procedure");
				System.out.println("Q - Quit");
				System.out.print("Pick : ");

				choice = S.next().toUpperCase();

				switch (choice) {
				case "1" : {
					browseResultSet();
					break;
				}
				case "2" : {
					invokeProcedure();
					break;
				}
				}
			} while (!choice.equals("Q"));

			c.close();

			System.out.println("Bye Bye :^)");
		}
		catch (Exception e) {
			System.err.println(e.getMessage());
		}
	}

	private static void browseResultSet() throws Exception {
		Statement s = c.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
		//scanning MYSQL select statements
		ResultSet rs = s.executeQuery("SELECT loan.no,loan.code,due\r\n FROM loan\r\n WHERE (`return` IS NULL) AND (year(due) = YEAR(CURRENT_DATE()));"); 

		// ToDo : Check ResultSet Contains Rows !
		// ToDo : Display ResultSet Rows !
		ResultSetMetaData rsmd = rs.getMetaData();
		int ColumnNumb = rsmd.getColumnCount();


		if(rs.first()) {
			System.out.println("-- BROWSE RESULTS --");
			do { 
				System.out.println("Database results:"); 
				for (int i=1; 1 <= ColumnNumb; i++) {

					if(i>1) System.out.println("");
					String columnValue = rs.getString(i);
					System.out.print((rsmd.getColumnName(i) + ":" + columnValue));

					System.out.print("");
				}
			}while (rs.next());
		}
		else {
			System.err.println("-- NO DATA AVAILIBLE --");
		}
	}

	private static void invokeProcedure() throws Exception {
		try { 

			//user input variables
			String ISBN = "";
			String StudentNo = ""; 
			
			//retrieving book, isbn and student no
			System.out.print("enter book isbn: \n");
			ISBN = S.next();
			
			System.out.print("Please enter student number :\n");
			StudentNo = S.next();

			//calling procedure
			String Procedure = "{CALL loan_new (?,?)}";
			CallableStatement cs = c.prepareCall(Procedure);

			//connecting input to isbn and student no's
			cs.setString(1,  ISBN);
			cs.setString (2,  StudentNo);
			cs.execute(); 
			}

		catch (Exception e) {
			System.out.println("invalid input!");
			System.err.println("SQLState: " + ((SQLException)e).getSQLState());
			System.err.println("Error code: " + ((SQLException)e).getErrorCode());
			System.err.println("Message: " + e.getMessage() + "\n");
		}

	}
}
