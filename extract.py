import requests 
import time
import json
import os
import datetime

# Get the API key from an environment variable
API_KEY = "bdnTOY3Wx7hYKcG7xjRo5ALgdcEYGiLv" #os.environ.get('API_KEY')


def retrieve_newest_monthly_lists():
    """
    Retrieve the 5 newest monthly lists from the NYTimes Books API and output them to a JSON file.
    
    Args:
        API_KEY (str): The NYTimes Books API key for authentication.
        
    Returns:
        list: A list of dictionaries containing the "list_name_encoded" and "oldest_published_date" keys 
            for the 5 newest monthly lists.
    """

     # Set up the API endpoint URL and parameters
    url = "https://api.nytimes.com/svc/books/v3/lists/names.json"
    params = {
        "api-key": f"{API_KEY}"
    }

    response = requests.get(url, params=params)
    data = response.json()
    
    # Filter for monthly lists
    data = [data for data in data["results"] if data["updated"]=="MONTHLY"]
    
    # Sort for finding the newest 4 lists
    data = sorted(data, key=lambda data: data['newest_published_date'], reverse=True)[:5]

    # Create a new list with only "list_name_encoded" and "oldest_publish_date" keys
    output_data = [{key:value for key,value in d.items() 
               if key in ['list_name_encoded', 'oldest_published_date']} 
              for d in data]
    
    # Write output to a JSON file
    with open("newest_monthly_lists.json", "w") as f:
        json.dump(output_data, f, indent=4)
    
    # Return the output data as the function of output
    return output_data


def retrieve_books(path_to_file, end_date=datetime.datetime.today().strftime('%Y-%m-%d')):
    """
    Retrieve the books for each monthly list specified in a JSON file.

    Args:
        path_to_file (str): The path to the input JSON file containing a list of monthly lists.
        end_date (str, optional): The last date for which to retrieve books. If None, all available books will be retrieved. Defaults to None.

    Returns:
        None
    """

    # Read the input data from the JSON file
    with open(path_to_file, 'r') as f:
        data = json.load(f)

    # Loop through each monthly list and retrieve the books for each month
    for lst in data:
        
        list_name_encoded = lst['list_name_encoded']
        oldest_published_date = lst['oldest_published_date']

        print(f"\t{list_name_encoded}")
        # Create a list to hold the API responses for each month
        responses = []

        # Initialize the API endpoint URL and parameters
        url = f'https://api.nytimes.com/svc/books/v3/lists/{oldest_published_date}/{list_name_encoded}.json'
        params = {
            'api-key': f'{API_KEY}',
            'offset':0
        }

        # Loop until there is no more data available or we reach the end date
        while True:
            print(list_name_encoded, oldest_published_date)
            # Send a GET request to the API endpoint with the current parameters
            url = f'https://api.nytimes.com/svc/books/v3/lists/{oldest_published_date}/{list_name_encoded}.json'
            response = requests.get(url, params=params)

            # Check if the response was successful
            if response.status_code == 200:
                # Parse the response data as JSON
                data = response.json()
                
                # Append the response data to the list of responses
                responses.append(data)
                
                num_results = data['num_results']
                page_num = 1

                
                # Go through all books
                while num_results >= 20:
                    print("Next page")
                    # Use offset to get the next batch of results
                    params['offset'] = page_num*20
                    next_page = requests.get(url, params=params)
                    
                    if next_page.status_code == 200:
                        next_page = response.json()
                        next_page = response.get("results", [])
                        data['results'].extend(next_page)
                    
                        # Iterate to the next page
                        page_num += 1
                    
                    if next_page.status_code == 429:
                        # NYTIMES API has 10 requests per minute limit
                        print('\t\t waiting ...')
                        time.sleep(30)
                        continue
                    
                # Check if there is more data available
                if (data["results"]['next_published_date'] <= end_date) and (data["results"]['next_published_date'] != ''):
                    # Update the parameters with the next_published_date
                    oldest_published_date = data["results"]['next_published_date']
                else:
                    break
            
            # Check if there is a timeout error
            elif response.status_code == 429:
                # NYTIMES API has 10 requests per minute limit
                print('\t\t waiting ...')
                time.sleep(30)

            else:
                print(f'Error: {response.status_code} - {response.reason}')
                break

        # Write the list of responses to a single NDJSON file
        output_filename = f'{list_name_encoded}.ndjson'
        with open(output_filename, 'w') as f:
            f.write(json.dumps(response) + '\n')

        # Print the path to the output file
        print(f'Output data saved to {os.path.abspath(output_filename)}')


if __name__ == "__main__":

    # Execute names script
    retrieve_newest_monthly_lists()

    # Execute second part
    retrieve_books("newest_monthly_lists.json")